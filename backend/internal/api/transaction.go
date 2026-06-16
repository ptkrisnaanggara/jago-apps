package api

import (
	"github.com/gin-gonic/gin"
	"github.com/ptkrisnaanggara/jago-apps/backend/internal/model"
)

// listTransactions returns the user's transaction history, newest first.
func (s *Server) listTransactions(c *gin.Context) {
	var txns []model.Transaction
	if err := s.db.
		Where("user_id = ?", currentUserID(c)).
		Order("created_at DESC").
		Find(&txns).Error; err != nil {
		respondError(c, 500, "internal", "failed to load transactions")
		return
	}
	respondOK(c, txns)
}
