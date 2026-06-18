package api

import (
	"errors"
	"fmt"
	"math/rand"
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/ptkrisnaanggara/jago-apps/backend/internal/model"
	"github.com/redis/go-redis/v9"
	"gorm.io/gorm"
)

// Admin OTP login: phone + one-time code, delivered over WhatsApp via WAHA.
// Redis keys are namespaced under "admin:" so they never collide with the
// customer auth flow.

func adminOtpKey(phone string) string      { return "admin:otp:" + phone }
func adminOtpRateKey(phone string) string  { return "admin:otp:rate:" + phone }
func adminOtpTriesKey(phone string) string { return "admin:otp:attempts:" + phone }

// findActiveAdmin looks up an enabled admin by phone.
func (s *Server) findActiveAdmin(phone string) (model.AdminUser, error) {
	var admin model.AdminUser
	err := s.db.First(&admin, "phone = ? AND status = ?", phone, model.AdminActive).Error
	if errors.Is(err, gorm.ErrRecordNotFound) {
		return admin, errAdminNotFound
	}
	return admin, err
}

type adminOTPRequest struct {
	Phone string `json:"phone" binding:"required"`
}

// requestAdminOTP validates the phone belongs to an active admin, rate-limits,
// generates a code, stores it in Redis, and sends it over WhatsApp (WAHA).
func (s *Server) requestAdminOTP(c *gin.Context) {
	var req adminOTPRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		respondError(c, 400, "bad_request", "phone is required")
		return
	}

	admin, err := s.findActiveAdmin(req.Phone)
	if errors.Is(err, errAdminNotFound) {
		respondError(c, 401, "unauthorized", "Nomor tidak terdaftar sebagai admin")
		return
	}
	if err != nil {
		respondError(c, 500, "internal", "failed to look up admin")
		return
	}

	// Fixed-window rate limit per phone.
	count, err := s.rdb.Incr(c, adminOtpRateKey(req.Phone)).Result()
	if err != nil {
		respondError(c, 500, "internal", "rate limiter unavailable")
		return
	}
	if count == 1 {
		s.rdb.Expire(c, adminOtpRateKey(req.Phone), s.cfg.OTPRateWindow)
	}
	if count > int64(s.cfg.OTPMaxRequests) {
		ttl, _ := s.rdb.TTL(c, adminOtpRateKey(req.Phone)).Result()
		if ttl > 0 {
			c.Header("Retry-After", strconv.Itoa(int(ttl.Seconds())))
		}
		respondError(c, 429, "rate_limited", "Terlalu banyak permintaan OTP. Coba lagi nanti.")
		return
	}
	s.rdb.Del(c, adminOtpTriesKey(req.Phone))

	code := s.cfg.OTPDemoCode
	if !s.cfg.OTPDemoMode {
		code = fmt.Sprintf("%06d", rand.Intn(1_000_000))
	}
	if err := s.rdb.Set(c, adminOtpKey(req.Phone), code, s.cfg.OTPTTL).Err(); err != nil {
		respondError(c, 500, "internal", "failed to store OTP")
		return
	}

	// Deliver over WhatsApp. In demo mode delivery is best-effort (the code is
	// also returned below); otherwise a send failure is fatal.
	delivered := false
	if s.waha.Enabled() {
		msg := fmt.Sprintf("Kode OTP Jago Admin Anda: %s. Berlaku %d menit. Jangan bagikan kode ini.",
			code, int(s.cfg.OTPTTL.Minutes()))
		if err := s.waha.SendText(c, admin.Phone, msg); err != nil {
			s.log.Warn("admin otp whatsapp send failed", "phone", admin.Phone, "error", err)
			if !s.cfg.OTPDemoMode {
				respondError(c, 502, "otp_delivery_failed", "Gagal mengirim OTP via WhatsApp")
				return
			}
		} else {
			delivered = true
		}
	} else if !s.cfg.OTPDemoMode {
		respondError(c, 503, "otp_delivery_unconfigured", "Pengiriman OTP belum dikonfigurasi")
		return
	}

	resp := gin.H{"message": "OTP sent", "delivered": delivered}
	if s.cfg.OTPDemoMode {
		resp["demoCode"] = code // convenience for the demo dashboard
	}
	respondOK(c, resp)
}

type adminVerifyRequest struct {
	Phone string `json:"phone" binding:"required"`
	Code  string `json:"code" binding:"required"`
}

// verifyAdminOTP checks the code (with a brute-force guard) and, on success,
// returns a JWT whose subject is the admin's ID plus the admin profile.
func (s *Server) verifyAdminOTP(c *gin.Context) {
	var req adminVerifyRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		respondError(c, 400, "bad_request", "phone and code are required")
		return
	}

	stored, err := s.rdb.Get(c, adminOtpKey(req.Phone)).Result()
	switch {
	case errors.Is(err, redis.Nil):
		respondError(c, 400, "otp_expired", "OTP expired or not requested")
		return
	case err != nil:
		respondError(c, 500, "internal", "failed to read OTP")
		return
	}

	// Brute-force guard: cap verify attempts per issued OTP.
	attempts, err := s.rdb.Incr(c, adminOtpTriesKey(req.Phone)).Result()
	if err != nil {
		respondError(c, 500, "internal", "rate limiter unavailable")
		return
	}
	if attempts == 1 {
		s.rdb.Expire(c, adminOtpTriesKey(req.Phone), s.cfg.OTPTTL)
	}
	if attempts > int64(s.cfg.OTPMaxVerifyAttempts) {
		s.rdb.Del(c, adminOtpKey(req.Phone))
		respondError(c, 429, "rate_limited", "Terlalu banyak percobaan. Minta OTP baru.")
		return
	}

	if stored != req.Code {
		respondError(c, 401, "otp_invalid", "Invalid OTP code")
		return
	}

	admin, err := s.findActiveAdmin(req.Phone)
	if errors.Is(err, errAdminNotFound) {
		respondError(c, 401, "unauthorized", "Nomor tidak terdaftar sebagai admin")
		return
	}
	if err != nil {
		respondError(c, 500, "internal", "failed to look up admin")
		return
	}

	s.rdb.Del(c, adminOtpKey(req.Phone), adminOtpTriesKey(req.Phone))

	tok, err := s.tokens.Generate(admin.ID)
	if err != nil {
		respondError(c, 500, "internal", "failed to issue token")
		return
	}
	respondOK(c, gin.H{"token": tok, "admin": admin})
}

// adminMe returns the signed-in admin's profile. Static-key callers have no
// associated admin row, so a service placeholder is returned.
func (s *Server) adminMe(c *gin.Context) {
	id := currentAdminID(c)
	if id == "" {
		respondOK(c, gin.H{"name": "Service Key", "role": "service", "phone": ""})
		return
	}
	var admin model.AdminUser
	if err := s.db.First(&admin, "id = ?", id).Error; err != nil {
		respondError(c, 404, "not_found", "admin not found")
		return
	}
	respondOK(c, admin)
}

// currentAdminID returns the authenticated admin's ID (set by adminRequired
// when authentication used a bearer token). Empty for static-key requests.
func currentAdminID(c *gin.Context) string {
	v, _ := c.Get(ctxAdminID)
	id, _ := v.(string)
	return id
}
