package api

import (
	"errors"
	"fmt"
	"math/rand"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/ptkrisnaanggara/jago-apps/backend/internal/model"
	"github.com/redis/go-redis/v9"
	"gorm.io/gorm"
)

func otpKey(phone string) string      { return "otp:" + phone }
func otpRateKey(phone string) string  { return "otp:rate:" + phone }
func otpTriesKey(phone string) string { return "otp:attempts:" + phone }

type otpRequest struct {
	Phone string `json:"phone" binding:"required"`
}

// requestOTP rate-limits per phone, then generates a code, stores it in Redis
// with a TTL, and (in demo mode) returns it for convenience.
func (s *Server) requestOTP(c *gin.Context) {
	var req otpRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		respondError(c, 400, "bad_request", "phone is required")
		return
	}

	// Fixed-window rate limit: INCR a counter whose TTL starts on the first
	// request in the window.
	count, err := s.rdb.Incr(c, otpRateKey(req.Phone)).Result()
	if err != nil {
		respondError(c, 500, "internal", "rate limiter unavailable")
		return
	}
	if count == 1 {
		s.rdb.Expire(c, otpRateKey(req.Phone), s.cfg.OTPRateWindow)
	}
	if count > int64(s.cfg.OTPMaxRequests) {
		ttl, _ := s.rdb.TTL(c, otpRateKey(req.Phone)).Result()
		if ttl > 0 {
			c.Header("Retry-After", strconv.Itoa(int(ttl.Seconds())))
		}
		respondError(c, 429, "rate_limited",
			"Terlalu banyak permintaan OTP. Coba lagi nanti.")
		return
	}

	// Fresh OTP → reset the verify-attempt counter for this phone.
	s.rdb.Del(c, otpTriesKey(req.Phone))

	code := s.cfg.OTPDemoCode
	if !s.cfg.OTPDemoMode {
		code = fmt.Sprintf("%06d", rand.Intn(1_000_000))
	}
	if err := s.rdb.Set(c, otpKey(req.Phone), code, s.cfg.OTPTTL).Err(); err != nil {
		respondError(c, 500, "internal", "failed to store OTP")
		return
	}

	resp := gin.H{"message": "OTP sent"}
	if s.cfg.OTPDemoMode {
		resp["demoCode"] = code
	}
	respondOK(c, resp)
}

type verifyRequest struct {
	Phone string `json:"phone" binding:"required"`
	Code  string `json:"code" binding:"required"`
	Name  string `json:"name"`
}

// verifyOTP checks the code, creates the user (and seeds their data) on first
// login, and returns a JWT.
func (s *Server) verifyOTP(c *gin.Context) {
	var req verifyRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		respondError(c, 400, "bad_request", "phone and code are required")
		return
	}

	stored, err := s.rdb.Get(c, otpKey(req.Phone)).Result()
	switch {
	case errors.Is(err, redis.Nil):
		respondError(c, 400, "otp_expired", "OTP expired or not requested")
		return
	case err != nil:
		respondError(c, 500, "internal", "failed to read OTP")
		return
	}

	// Brute-force guard: cap verify attempts per issued OTP.
	attempts, err := s.rdb.Incr(c, otpTriesKey(req.Phone)).Result()
	if err != nil {
		respondError(c, 500, "internal", "rate limiter unavailable")
		return
	}
	if attempts == 1 {
		s.rdb.Expire(c, otpTriesKey(req.Phone), s.cfg.OTPTTL)
	}
	if attempts > int64(s.cfg.OTPMaxVerifyAttempts) {
		// Too many guesses → invalidate the OTP so a new one must be requested.
		s.rdb.Del(c, otpKey(req.Phone))
		respondError(c, 429, "rate_limited",
			"Terlalu banyak percobaan. Minta OTP baru.")
		return
	}

	if stored != req.Code {
		respondError(c, 401, "otp_invalid", "Invalid OTP code")
		return
	}
	s.rdb.Del(c, otpKey(req.Phone), otpTriesKey(req.Phone))

	var user model.User
	err = s.db.Where("phone = ?", req.Phone).First(&user).Error
	if errors.Is(err, gorm.ErrRecordNotFound) {
		name := req.Name
		if name == "" {
			name = "Nasabah Jago"
		}
		user = model.User{Name: name, Phone: req.Phone}
		if err := s.db.Create(&user).Error; err != nil {
			respondError(c, 500, "internal", "failed to create user")
			return
		}
		if err := s.seedNewUser(&user); err != nil {
			respondError(c, 500, "internal", "failed to seed account")
			return
		}
	} else if err != nil {
		respondError(c, 500, "internal", "failed to look up user")
		return
	}

	tok, err := s.tokens.Generate(user.ID)
	if err != nil {
		respondError(c, 500, "internal", "failed to issue token")
		return
	}
	respondOK(c, gin.H{"token": tok, "user": user})
}

// me returns the authenticated user.
func (s *Server) me(c *gin.Context) {
	var user model.User
	if err := s.db.First(&user, "id = ?", currentUserID(c)).Error; err != nil {
		respondError(c, 404, "not_found", "user not found")
		return
	}
	respondOK(c, user)
}

// seedNewUser gives a fresh account starting data so the app's screens are
// populated immediately (mirrors the Flutter mock repositories).
func (s *Server) seedNewUser(u *model.User) error {
	target1 := int64(10_000_000)
	target2 := int64(5_000_000)
	now := time.Now()

	return s.db.Transaction(func(tx *gorm.DB) error {
		account := model.Account{
			UserID:        u.ID,
			HolderName:    u.Name,
			AccountNumber: randomAccountNumber(),
			Balance:       12_750_000,
		}
		if err := tx.Create(&account).Error; err != nil {
			return err
		}

		pockets := []model.Pocket{
			{UserID: u.ID, Name: "Kantong Utama", Type: model.PocketMain, Balance: 1_000_000, IsMain: true},
			{UserID: u.ID, Name: "Dana Darurat", Type: model.PocketSaving, Balance: 4_500_000, Target: &target1},
			{UserID: u.ID, Name: "Liburan ke Bali", Type: model.PocketSaving, Balance: 2_300_000, Target: &target2},
		}
		if err := tx.Create(&pockets).Error; err != nil {
			return err
		}

		cards := []model.Card{
			{UserID: u.ID, Label: "Kartu Utama", Number: "4567 8901 2345 6789", HolderName: u.Name, Expiry: "08/27", CVV: "123", Type: model.CardPhysical},
			{UserID: u.ID, Label: "Kartu Virtual", Number: "5234 1122 8890 4521", HolderName: u.Name, Expiry: "11/26", CVV: "456", Type: model.CardVirtual},
		}
		if err := tx.Create(&cards).Error; err != nil {
			return err
		}

		txns := []model.Transaction{
			{UserID: u.ID, Title: "Gaji Bulanan", Category: "Pemasukan", Amount: 9_500_000, Type: model.TxIncome},
			{UserID: u.ID, Title: "Kopi Kenangan", Category: "Makan & Minum", Amount: 28_000, Type: model.TxExpense},
		}
		if err := tx.Create(&txns).Error; err != nil {
			return err
		}

		bills := []model.Bill{
			{UserID: u.ID, Biller: "PLN Pascabayar", Category: "Listrik", Amount: 320_000, DueDate: now.AddDate(0, 0, 3), Recurrence: model.RecurrenceMonthly},
			{UserID: u.ID, Biller: "IndiHome", Category: "Internet", Amount: 410_000, DueDate: now.AddDate(0, 0, 8), Recurrence: model.RecurrenceMonthly},
		}
		if err := tx.Create(&bills).Error; err != nil {
			return err
		}

		contacts := []model.Contact{
			{UserID: u.ID, Name: "Budi Santoso", BankName: "Bank Jago", AccountNumber: "100 8420 5566"},
			{UserID: u.ID, Name: "Siti Rahmawati", BankName: "BCA", AccountNumber: "012 3456 7890"},
			{UserID: u.ID, Name: "Andi Pratama", BankName: "Mandiri", AccountNumber: "137 0099 8877"},
			{UserID: u.ID, Name: "Dewi Lestari", BankName: "BNI", AccountNumber: "088 1212 3434"},
			{UserID: u.ID, Name: "Eko Wijaya", BankName: "Bank Jago", AccountNumber: "100 7711 2299"},
		}
		return tx.Create(&contacts).Error
	})
}

func randomAccountNumber() string {
	return fmt.Sprintf("100 %04d %04d", rand.Intn(10000), rand.Intn(10000))
}
