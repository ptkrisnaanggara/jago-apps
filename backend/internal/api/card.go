package api

import (
	"github.com/gin-gonic/gin"
	"github.com/ptkrisnaanggara/jago-apps/backend/internal/model"
)

// listCards returns the user's payment cards.
func (s *Server) listCards(c *gin.Context) {
	var cards []model.Card
	if err := s.db.
		Where("user_id = ?", currentUserID(c)).
		Order("created_at ASC").
		Find(&cards).Error; err != nil {
		respondError(c, 500, "internal", "failed to load cards")
		return
	}
	respondOK(c, cards)
}

type freezeRequest struct {
	Frozen bool `json:"frozen"`
}

// setCardFrozen freezes or unfreezes a card.
func (s *Server) setCardFrozen(c *gin.Context) {
	var req freezeRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		respondError(c, 400, "bad_request", "frozen is required")
		return
	}

	uid := currentUserID(c)
	id := c.Param("id")
	res := s.db.Model(&model.Card{}).
		Where("id = ? AND user_id = ?", id, uid).
		Update("is_frozen", req.Frozen)
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
	respondOK(c, card)
}
