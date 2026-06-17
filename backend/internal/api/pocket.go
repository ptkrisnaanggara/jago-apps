package api

import (
	"errors"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/ptkrisnaanggara/jago-apps/backend/internal/model"
	"gorm.io/gorm"
	"gorm.io/gorm/clause"
)

var (
	errPocketNotFound = errors.New("pocket not found")
	errPocketLocked   = errors.New("pocket locked")
)

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
		if src.Locked {
			return errPocketLocked
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
	case errors.Is(err, errPocketLocked):
		respondError(c, 423, "pocket_locked", "Kantong terkunci")
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

type lockRequest struct {
	Until *time.Time `json:"until"`
}

// lockPocket locks a pocket (optionally until a date).
func (s *Server) lockPocket(c *gin.Context) {
	var req lockRequest
	_ = c.ShouldBindJSON(&req)
	res := s.db.Model(&model.Pocket{}).
		Where("id = ? AND user_id = ?", c.Param("id"), currentUserID(c)).
		Updates(map[string]any{"locked": true, "lock_until": req.Until})
	s.respondPocketsAfterUpdate(c, res)
}

// unlockPocket removes a pocket's lock.
func (s *Server) unlockPocket(c *gin.Context) {
	res := s.db.Model(&model.Pocket{}).
		Where("id = ? AND user_id = ?", c.Param("id"), currentUserID(c)).
		Updates(map[string]any{"locked": false, "lock_until": nil})
	s.respondPocketsAfterUpdate(c, res)
}

type autosaveRequest struct {
	Amount    int64  `json:"amount"`
	Frequency string `json:"frequency"`
}

// setAutosave configures a pocket's autosave (amount 0 disables it).
func (s *Server) setAutosave(c *gin.Context) {
	var req autosaveRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		respondError(c, 400, "bad_request", "amount and frequency are required")
		return
	}
	freq := req.Frequency
	if req.Amount <= 0 {
		freq = "none"
		req.Amount = 0
	}
	res := s.db.Model(&model.Pocket{}).
		Where("id = ? AND user_id = ?", c.Param("id"), currentUserID(c)).
		Updates(map[string]any{
			"autosave_amount":    req.Amount,
			"autosave_frequency": freq,
		})
	s.respondPocketsAfterUpdate(c, res)
}

// runAutosave executes one autosave cycle: move the autosave amount from the
// main pocket into this pocket (what a scheduler would trigger per frequency).
func (s *Server) runAutosave(c *gin.Context) {
	uid := currentUserID(c)
	id := c.Param("id")
	err := s.db.Transaction(func(tx *gorm.DB) error {
		var target model.Pocket
		if err := tx.Clauses(clause.Locking{Strength: "UPDATE"}).
			First(&target, "id = ? AND user_id = ?", id, uid).Error; err != nil {
			return err
		}
		if target.AutosaveAmount <= 0 {
			return errPocketNotFound // nothing to do
		}
		var main model.Pocket
		if err := tx.Clauses(clause.Locking{Strength: "UPDATE"}).
			First(&main, "user_id = ? AND is_main = ?", uid, true).Error; err != nil {
			return err
		}
		if main.Balance < target.AutosaveAmount {
			return errInsufficientFunds
		}
		if err := tx.Model(&main).Update("balance", main.Balance-target.AutosaveAmount).Error; err != nil {
			return err
		}
		return tx.Model(&target).Update("balance", target.Balance+target.AutosaveAmount).Error
	})

	switch {
	case errors.Is(err, errPocketNotFound):
		respondError(c, 404, "not_found", "pocket or autosave not found")
		return
	case errors.Is(err, errInsufficientFunds):
		respondError(c, 422, "insufficient_funds", "Saldo kantong utama tidak mencukupi")
		return
	case err != nil:
		respondError(c, 500, "internal", "autosave failed")
		return
	}
	s.respondPockets(c, uid)
}

// respondPocketsAfterUpdate maps a gorm update result then returns the list.
func (s *Server) respondPocketsAfterUpdate(c *gin.Context, res *gorm.DB) {
	if res.Error != nil {
		respondError(c, 500, "internal", "failed to update pocket")
		return
	}
	if res.RowsAffected == 0 {
		respondError(c, 404, "not_found", "pocket not found")
		return
	}
	s.respondPockets(c, currentUserID(c))
}

func (s *Server) respondPockets(c *gin.Context, uid string) {
	pockets, err := s.userPockets(uid)
	if err != nil {
		respondError(c, 500, "internal", "failed to load pockets")
		return
	}
	respondOK(c, pockets)
}

func (s *Server) userPockets(userID string) ([]model.Pocket, error) {
	memberPocketIDs := s.db.Model(&model.PocketMember{}).
		Select("pocket_id").Where("user_id = ?", userID)

	var pockets []model.Pocket
	err := s.db.
		Where("user_id = ? OR id::text IN (?)", userID, memberPocketIDs).
		Order("is_main DESC, created_at ASC").
		Find(&pockets).Error
	if err != nil {
		return nil, err
	}
	for i := range pockets {
		if pockets[i].UserID == userID {
			pockets[i].Role = "owner"
		} else {
			pockets[i].Role = "member"
		}
	}
	return pockets, nil
}
