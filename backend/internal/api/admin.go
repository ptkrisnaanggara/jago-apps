package api

import (
	"github.com/gin-gonic/gin"
	"github.com/ptkrisnaanggara/jago-apps/backend/internal/model"
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
// the owner's name, newest first. Supports `?page=&limit=`.
func (s *Server) listAdminTransactions(c *gin.Context) {
	p := parsePage(c)

	var total int64
	if err := s.db.Model(&model.Transaction{}).Count(&total).Error; err != nil {
		respondError(c, 500, "internal", "failed to load transactions")
		return
	}

	var rows []adminTransaction
	if err := s.db.Model(&model.Transaction{}).
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
