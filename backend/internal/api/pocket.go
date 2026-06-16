package api

import (
	"github.com/gin-gonic/gin"
	"github.com/ptkrisnaanggara/jago-apps/backend/internal/model"
)

// listPockets returns the user's savings pockets (main first).
func (s *Server) listPockets(c *gin.Context) {
	var pockets []model.Pocket
	if err := s.db.
		Where("user_id = ?", currentUserID(c)).
		Order("is_main DESC, created_at ASC").
		Find(&pockets).Error; err != nil {
		respondError(c, 500, "internal", "failed to load pockets")
		return
	}
	respondOK(c, pockets)
}
