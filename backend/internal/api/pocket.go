package api

import (
	"errors"

	"github.com/gin-gonic/gin"
	"github.com/ptkrisnaanggara/jago-apps/backend/internal/model"
	"gorm.io/gorm"
	"gorm.io/gorm/clause"
)

var errPocketNotFound = errors.New("pocket not found")

// listPockets returns the user's savings pockets (main first).
func (s *Server) listPockets(c *gin.Context) {
	pockets, err := s.userPockets(currentUserID(c))
	if err != nil {
		respondError(c, 500, "internal", "failed to load pockets")
		return
	}
	respondOK(c, pockets)
}

type createPocketRequest struct {
	Name   string           `json:"name" binding:"required"`
	Type   model.PocketType `json:"type"`
	Target *int64           `json:"target"`
}

// createPocket adds a new (empty) pocket. Defaults to a spending pocket.
func (s *Server) createPocket(c *gin.Context) {
	var req createPocketRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		respondError(c, 400, "bad_request", "name is required")
		return
	}
	t := req.Type
	if t != model.PocketSpending && t != model.PocketSaving {
		t = model.PocketSpending // 'main' is reserved for the seeded pocket
	}
	pocket := model.Pocket{
		UserID: currentUserID(c),
		Name:   req.Name,
		Type:   t,
		Target: req.Target,
	}
	if err := s.db.Create(&pocket).Error; err != nil {
		respondError(c, 500, "internal", "failed to create pocket")
		return
	}
	respondCreated(c, pocket)
}

type movePocketRequest struct {
	FromPocketID string `json:"fromPocketId" binding:"required"`
	ToPocketID   string `json:"toPocketId" binding:"required"`
	Amount       int64  `json:"amount" binding:"required,gt=0"`
}

// movePocket atomically moves money between two of the user's pockets.
func (s *Server) movePocket(c *gin.Context) {
	var req movePocketRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		respondError(c, 400, "bad_request", "fromPocketId, toPocketId and a positive amount are required")
		return
	}
	if req.FromPocketID == req.ToPocketID {
		respondError(c, 400, "bad_request", "source and destination must differ")
		return
	}

	uid := currentUserID(c)
	err := s.db.Transaction(func(tx *gorm.DB) error {
		// Lock both rows (ordered by id to avoid deadlocks).
		var pockets []model.Pocket
		if err := tx.Clauses(clause.Locking{Strength: "UPDATE"}).
			Where("user_id = ? AND id IN ?", uid, []string{req.FromPocketID, req.ToPocketID}).
			Order("id").Find(&pockets).Error; err != nil {
			return err
		}
		var src, dst *model.Pocket
		for i := range pockets {
			switch pockets[i].ID {
			case req.FromPocketID:
				src = &pockets[i]
			case req.ToPocketID:
				dst = &pockets[i]
			}
		}
		if src == nil || dst == nil {
			return errPocketNotFound
		}
		if src.Balance < req.Amount {
			return errInsufficientFunds
		}
		if err := tx.Model(src).Update("balance", src.Balance-req.Amount).Error; err != nil {
			return err
		}
		return tx.Model(dst).Update("balance", dst.Balance+req.Amount).Error
	})

	switch {
	case errors.Is(err, errPocketNotFound):
		respondError(c, 404, "not_found", "pocket not found")
		return
	case errors.Is(err, errInsufficientFunds):
		respondError(c, 422, "insufficient_funds", "Saldo kantong tidak mencukupi")
		return
	case err != nil:
		respondError(c, 500, "internal", "move failed")
		return
	}

	pockets, err := s.userPockets(uid)
	if err != nil {
		respondError(c, 500, "internal", "failed to load pockets")
		return
	}
	respondOK(c, pockets)
}

func (s *Server) userPockets(userID string) ([]model.Pocket, error) {
	var pockets []model.Pocket
	err := s.db.
		Where("user_id = ?", userID).
		Order("is_main DESC, created_at ASC").
		Find(&pockets).Error
	return pockets, err
}
