package api

import (
	"github.com/gin-gonic/gin"
	"github.com/ptkrisnaanggara/jago-apps/backend/internal/model"
	"gorm.io/gorm"
)

// adminBill is a bill joined with its owner's name for the admin list.
type adminBill struct {
	ID         string `json:"id"`
	UserID     string `json:"userId"`
	UserName   string `json:"userName"`
	Biller     string `json:"biller"`
	Category   string `json:"category"`
	Amount     int64  `json:"amount"`
	DueDate    string `json:"dueDate"`
	IsPaid     bool   `json:"isPaid"`
	Recurrence string `json:"recurrence"`
}

// listAdminBills returns a page of bills across all users with the owner's name,
// soonest due first. Supports `?page=&limit=` and `?status=paid|unpaid`.
func (s *Server) listAdminBills(c *gin.Context) {
	p := parsePage(c)

	base := func() *gorm.DB {
		q := s.db.Model(&model.Bill{})
		switch c.Query("status") {
		case "paid":
			q = q.Where("bills.is_paid = ?", true)
		case "unpaid":
			q = q.Where("bills.is_paid = ?", false)
		}
		return q
	}

	var total int64
	if err := base().Count(&total).Error; err != nil {
		respondError(c, 500, "internal", "failed to load bills")
		return
	}

	var rows []adminBill
	if err := base().
		Select("bills.id, bills.user_id, users.name AS user_name, bills.biller, " +
			"bills.category, bills.amount, bills.due_date, bills.is_paid, bills.recurrence").
		Joins("LEFT JOIN users ON users.id::text = bills.user_id").
		Where("bills.deleted_at IS NULL").
		Order("bills.due_date ASC").
		Limit(p.Limit).Offset(p.Offset).
		Scan(&rows).Error; err != nil {
		respondError(c, 500, "internal", "failed to load bills")
		return
	}

	respondPaginated(c, rows, p, total)
}
