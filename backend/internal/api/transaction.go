package api

import (
	"github.com/gin-gonic/gin"
	"github.com/ptkrisnaanggara/jago-apps/backend/internal/model"
)

// listTransactions returns a page of the user's transaction history, newest
// first. Supports `?page=&limit=`.
func (s *Server) listTransactions(c *gin.Context) {
	uid := currentUserID(c)
	p := parsePage(c)

	var total int64
	if err := s.db.Model(&model.Transaction{}).
		Where("user_id = ?", uid).Count(&total).Error; err != nil {
		respondError(c, 500, "internal", "failed to load transactions")
		return
	}

	var txns []model.Transaction
	if err := s.db.
		Where("user_id = ?", uid).
		Order("created_at DESC").
		Limit(p.Limit).Offset(p.Offset).
		Find(&txns).Error; err != nil {
		respondError(c, 500, "internal", "failed to load transactions")
		return
	}
	respondPaginated(c, txns, p, total)
}
