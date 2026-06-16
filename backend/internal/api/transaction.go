package api

import (
	"github.com/gin-gonic/gin"
	"github.com/ptkrisnaanggara/jago-apps/backend/internal/model"
	"gorm.io/gorm"
)

// listTransactions returns a page of the user's transaction history, newest
// first. Supports `?page=&limit=` and `?type=income|expense`.
func (s *Server) listTransactions(c *gin.Context) {
	uid := currentUserID(c)
	p := parsePage(c)

	// Base filter, reused for the count and the page query.
	base := func() *gorm.DB {
		q := s.db.Model(&model.Transaction{}).Where("user_id = ?", uid)
		if t := c.Query("type"); t == string(model.TxIncome) || t == string(model.TxExpense) {
			q = q.Where("type = ?", t)
		}
		return q
	}

	var total int64
	if err := base().Count(&total).Error; err != nil {
		respondError(c, 500, "internal", "failed to load transactions")
		return
	}

	var txns []model.Transaction
	if err := base().
		Order("created_at DESC").
		Limit(p.Limit).Offset(p.Offset).
		Find(&txns).Error; err != nil {
		respondError(c, 500, "internal", "failed to load transactions")
		return
	}
	respondPaginated(c, txns, p, total)
}
