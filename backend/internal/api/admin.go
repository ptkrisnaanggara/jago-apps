package api

import (
	"errors"

	"github.com/gin-gonic/gin"
	"github.com/ptkrisnaanggara/jago-apps/backend/internal/model"
	"gorm.io/gorm"
)

// admin.go powers the web admin dashboard (frontend/). These endpoints are
// guarded by adminRequired() (X-Admin-Key header), not user JWTs, and give an
// operator a read-only view across all users.

// adminStats is the dashboard's headline summary.
type adminStats struct {
	Users         int64 `json:"users"`
	Accounts      int64 `json:"accounts"`
	Pockets       int64 `json:"pockets"`
	Cards         int64 `json:"cards"`
	Transactions  int64 `json:"transactions"`
	Transfers     int64 `json:"transfers"`
	Bills         int64 `json:"bills"`
	Pools         int64 `json:"pools"`
	TotalBalance  int64 `json:"totalBalance"`  // summed across all accounts
	PocketBalance int64 `json:"pocketBalance"` // summed across all pockets
}

// getAdminStats returns aggregate counts and balances for the dashboard cards.
func (s *Server) getAdminStats(c *gin.Context) {
	var st adminStats

	count := func(m any, dst *int64) bool {
		if err := s.db.Model(m).Count(dst).Error; err != nil {
			respondError(c, 500, "internal", "failed to load stats")
			return false
		}
		return true
	}

	if !count(&model.User{}, &st.Users) ||
		!count(&model.Account{}, &st.Accounts) ||
		!count(&model.Pocket{}, &st.Pockets) ||
		!count(&model.Card{}, &st.Cards) ||
		!count(&model.Transaction{}, &st.Transactions) ||
		!count(&model.Transfer{}, &st.Transfers) ||
		!count(&model.Bill{}, &st.Bills) ||
		!count(&model.MoneyPool{}, &st.Pools) {
		return
	}

	// COALESCE keeps the sum at 0 when there are no rows.
	if err := s.db.Model(&model.Account{}).
		Select("COALESCE(SUM(balance), 0)").Scan(&st.TotalBalance).Error; err != nil {
		respondError(c, 500, "internal", "failed to load stats")
		return
	}
	if err := s.db.Model(&model.Pocket{}).
		Select("COALESCE(SUM(balance), 0)").Scan(&st.PocketBalance).Error; err != nil {
		respondError(c, 500, "internal", "failed to load stats")
		return
	}

	respondOK(c, st)
}

// adminUser is a user row joined with its account balance for the users table.
type adminUser struct {
	ID            string `json:"id"`
	Name          string `json:"name"`
	Phone         string `json:"phone"`
	AccountNumber string `json:"accountNumber"`
	Balance       int64  `json:"balance"`
	CreatedAt     string `json:"createdAt"`
}

// listAdminUsers returns a page of users with their account balance, newest
// first. Supports `?page=&limit=`.
func (s *Server) listAdminUsers(c *gin.Context) {
	p := parsePage(c)

	var total int64
	if err := s.db.Model(&model.User{}).Count(&total).Error; err != nil {
		respondError(c, 500, "internal", "failed to load users")
		return
	}

	var rows []adminUser
	if err := s.db.Model(&model.User{}).
		Select("users.id, users.name, users.phone, users.created_at, " +
			"accounts.account_number, COALESCE(accounts.balance, 0) AS balance").
		Joins("LEFT JOIN accounts ON accounts.user_id = users.id::text AND accounts.deleted_at IS NULL").
		Where("users.deleted_at IS NULL").
		Order("users.created_at DESC").
		Limit(p.Limit).Offset(p.Offset).
		Scan(&rows).Error; err != nil {
		respondError(c, 500, "internal", "failed to load users")
		return
	}

	respondPaginated(c, rows, p, total)
}

// adminTransaction is a transaction joined with its owner's name.
type adminTransaction struct {
	ID        string `json:"id"`
	UserID    string `json:"userId"`
	UserName  string `json:"userName"`
	Title     string `json:"title"`
	Category  string `json:"category"`
	Amount    int64  `json:"amount"`
	Type      string `json:"type"`
	CreatedAt string `json:"createdAt"`
}

// listAdminTransactions returns a page of transactions across all users with
// the owner's name, newest first. Supports `?page=&limit=`, `?type=income|
// expense`, and `?userId=` to scope to one user.
func (s *Server) listAdminTransactions(c *gin.Context) {
	p := parsePage(c)

	base := func() *gorm.DB {
		q := s.db.Model(&model.Transaction{})
		if t := c.Query("type"); t == string(model.TxIncome) || t == string(model.TxExpense) {
			q = q.Where("transactions.type = ?", t)
		}
		if uid := c.Query("userId"); uid != "" {
			q = q.Where("transactions.user_id = ?", uid)
		}
		return q
	}

	var total int64
	if err := base().Count(&total).Error; err != nil {
		respondError(c, 500, "internal", "failed to load transactions")
		return
	}

	var rows []adminTransaction
	if err := base().
		Select("transactions.id, transactions.user_id, users.name AS user_name, " +
			"transactions.title, transactions.category, transactions.amount, " +
			"transactions.type, transactions.created_at").
		Joins("LEFT JOIN users ON users.id::text = transactions.user_id").
		Where("transactions.deleted_at IS NULL").
		Order("transactions.created_at DESC").
		Limit(p.Limit).Offset(p.Offset).
		Scan(&rows).Error; err != nil {
		respondError(c, 500, "internal", "failed to load transactions")
		return
	}

	respondPaginated(c, rows, p, total)
}

// adminUserDetail bundles everything an operator needs about one user.
type adminUserDetail struct {
	User         model.User          `json:"user"`
	Account      *model.Account      `json:"account"`
	Pockets      []model.Pocket      `json:"pockets"`
	Cards        []model.Card        `json:"cards"`
	Bills        []model.Bill        `json:"bills"`
	Pools        []model.MoneyPool   `json:"pools"`
	Transactions []model.Transaction `json:"transactions"` // 10 most recent
}

// getAdminUser returns the full detail bundle for one user by ID.
func (s *Server) getAdminUser(c *gin.Context) {
	id := c.Param("id")

	var detail adminUserDetail
	if err := s.db.First(&detail.User, "id = ?", id).Error; err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			respondError(c, 404, "not_found", "user not found")
			return
		}
		respondError(c, 500, "internal", "failed to load user")
		return
	}

	var account model.Account
	if err := s.db.First(&account, "user_id = ?", id).Error; err == nil {
		detail.Account = &account
	} else if !errors.Is(err, gorm.ErrRecordNotFound) {
		respondError(c, 500, "internal", "failed to load user")
		return
	}

	// On any related-list error we fail the whole request so the UI never shows
	// a partial, misleading picture.
	load := func(err error) bool {
		if err != nil {
			respondError(c, 500, "internal", "failed to load user")
			return false
		}
		return true
	}

	if !load(s.db.Where("user_id = ?", id).Order("is_main DESC, created_at ASC").Find(&detail.Pockets).Error) ||
		!load(s.db.Where("user_id = ?", id).Order("created_at ASC").Find(&detail.Cards).Error) ||
		!load(s.db.Where("user_id = ?", id).Order("due_date ASC").Find(&detail.Bills).Error) ||
		!load(s.db.Where("owner_user_id = ?", id).Order("created_at DESC").Find(&detail.Pools).Error) ||
		!load(s.db.Where("user_id = ?", id).Order("created_at DESC").Limit(10).Find(&detail.Transactions).Error) {
		return
	}

	respondOK(c, detail)
}

// adminPool is a money pool joined with its owner's name.
type adminPool struct {
	ID          string `json:"id"`
	OwnerUserID string `json:"ownerUserId"`
	OwnerName   string `json:"ownerName"`
	Title       string `json:"title"`
	Target      int64  `json:"target"`
	Collected   int64  `json:"collected"`
	Status      string `json:"status"`
	CreatedAt   string `json:"createdAt"`
}

// listAdminPools returns a page of money pools across all users with the owner's
// name, newest first. Supports `?page=&limit=`.
func (s *Server) listAdminPools(c *gin.Context) {
	p := parsePage(c)

	var total int64
	if err := s.db.Model(&model.MoneyPool{}).Count(&total).Error; err != nil {
		respondError(c, 500, "internal", "failed to load pools")
		return
	}

	var rows []adminPool
	if err := s.db.Model(&model.MoneyPool{}).
		Select("money_pools.id, money_pools.owner_user_id, users.name AS owner_name, " +
			"money_pools.title, money_pools.target, money_pools.collected, " +
			"money_pools.status, money_pools.created_at").
		Joins("LEFT JOIN users ON users.id::text = money_pools.owner_user_id").
		Where("money_pools.deleted_at IS NULL").
		Order("money_pools.created_at DESC").
		Limit(p.Limit).Offset(p.Offset).
		Scan(&rows).Error; err != nil {
		respondError(c, 500, "internal", "failed to load pools")
		return
	}

	respondPaginated(c, rows, p, total)
}

// adminSetCardFrozen freezes/unfreezes any user's card (operator support). The
// body is `{"frozen": true|false}`. Returns the updated card.
func (s *Server) adminSetCardFrozen(c *gin.Context) {
	var req freezeRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		respondError(c, 400, "bad_request", "frozen is required")
		return
	}

	id := c.Param("id")
	res := s.db.Model(&model.Card{}).Where("id = ?", id).Update("is_frozen", req.Frozen)
	if res.Error != nil {
		respondError(c, 500, "internal", "failed to update card")
		return
	}
	if res.RowsAffected == 0 {
		respondError(c, 404, "not_found", "card not found")
		return
	}

	var card model.Card
	if err := s.db.First(&card, "id = ?", id).Error; err != nil {
		respondError(c, 500, "internal", "failed to load card")
		return
	}
	s.log.Info("admin_card_freeze", "card_id", id, "frozen", req.Frozen)
	respondOK(c, card)
}
