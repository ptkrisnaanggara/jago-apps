package api

import (
	"errors"

	"github.com/gin-gonic/gin"
	"github.com/ptkrisnaanggara/jago-apps/backend/internal/model"
	"gorm.io/gorm"
	"gorm.io/gorm/clause"
)

type shareRequest struct {
	Phone string `json:"phone" binding:"required"`
}

// sharePocket adds another user (by phone) as a member of the pocket.
func (s *Server) sharePocket(c *gin.Context) {
	var req shareRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		respondError(c, 400, "bad_request", "phone is required")
		return
	}

	uid := currentUserID(c)
	id := c.Param("id")

	var pocket model.Pocket
	if err := s.db.First(&pocket, "id = ? AND user_id = ?", id, uid).Error; err != nil {
		respondError(c, 404, "not_found", "pocket not found") // owner-only
		return
	}

	var target model.User
	if err := s.db.First(&target, "phone = ?", req.Phone).Error; err != nil {
		respondError(c, 404, "user_not_found", "Pengguna tidak ditemukan")
		return
	}
	if target.ID == uid {
		respondError(c, 400, "bad_request", "cannot share with yourself")
		return
	}

	var count int64
	s.db.Model(&model.PocketMember{}).
		Where("pocket_id = ? AND user_id = ?", id, target.ID).Count(&count)
	if count == 0 {
		if err := s.db.Create(&model.PocketMember{
			PocketID: id, UserID: target.ID, Role: "member",
		}).Error; err != nil {
			respondError(c, 500, "internal", "failed to share pocket")
			return
		}
	}
	s.db.Model(&pocket).Update("shared", true)
	s.respondPockets(c, uid)
}

type pocketMember struct {
	UserID string `json:"userId"`
	Name   string `json:"name"`
	Role   string `json:"role"`
}

// listMembers returns the owner + members of a shared pocket.
func (s *Server) listMembers(c *gin.Context) {
	uid := currentUserID(c)
	pocket, ok := s.canAccessPocket(c.Param("id"), uid)
	if !ok {
		respondError(c, 404, "not_found", "pocket not found")
		return
	}

	members := []pocketMember{}
	var owner model.User
	if err := s.db.First(&owner, "id = ?", pocket.UserID).Error; err == nil {
		members = append(members, pocketMember{UserID: owner.ID, Name: owner.Name, Role: "owner"})
	}

	var rows []model.PocketMember
	s.db.Where("pocket_id = ?", pocket.ID).Order("created_at ASC").Find(&rows)
	for _, m := range rows {
		var u model.User
		if err := s.db.First(&u, "id = ?", m.UserID).Error; err == nil {
			members = append(members, pocketMember{UserID: u.ID, Name: u.Name, Role: m.Role})
		}
	}
	respondOK(c, members)
}

type depositRequest struct {
	Amount int64 `json:"amount" binding:"required,gt=0"`
}

// depositPocket moves money from the caller's main pocket into a (shared)
// pocket they can access — the collaborative-funding action.
func (s *Server) depositPocket(c *gin.Context) {
	var req depositRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		respondError(c, 400, "bad_request", "a positive amount is required")
		return
	}

	uid := currentUserID(c)
	id := c.Param("id")
	if _, ok := s.canAccessPocket(id, uid); !ok {
		respondError(c, 404, "not_found", "pocket not found")
		return
	}

	err := s.db.Transaction(func(tx *gorm.DB) error {
		var main model.Pocket
		if err := tx.Clauses(clause.Locking{Strength: "UPDATE"}).
			First(&main, "user_id = ? AND is_main = ?", uid, true).Error; err != nil {
			return err
		}
		if main.Balance < req.Amount {
			return errInsufficientFunds
		}
		var target model.Pocket
		if err := tx.Clauses(clause.Locking{Strength: "UPDATE"}).
			First(&target, "id = ?", id).Error; err != nil {
			return err
		}
		if err := tx.Model(&main).Update("balance", main.Balance-req.Amount).Error; err != nil {
			return err
		}
		if err := tx.Model(&target).Update("balance", target.Balance+req.Amount).Error; err != nil {
			return err
		}
		return tx.Create(&model.Transaction{
			UserID:   uid,
			Title:    "Setor " + target.Name,
			Category: "Kantong Bersama",
			Amount:   req.Amount,
			Type:     model.TxExpense,
		}).Error
	})

	switch {
	case errors.Is(err, errInsufficientFunds):
		respondError(c, 422, "insufficient_funds", "Saldo kantong utama tidak mencukupi")
		return
	case err != nil:
		respondError(c, 500, "internal", "deposit failed")
		return
	}
	s.respondPockets(c, uid)
}

// canAccessPocket reports whether uid is the owner or a member of the pocket.
func (s *Server) canAccessPocket(pocketID, uid string) (model.Pocket, bool) {
	var pocket model.Pocket
	if err := s.db.First(&pocket, "id = ?", pocketID).Error; err != nil {
		return pocket, false
	}
	if pocket.UserID == uid {
		return pocket, true
	}
	var count int64
	s.db.Model(&model.PocketMember{}).
		Where("pocket_id = ? AND user_id = ?", pocketID, uid).Count(&count)
	return pocket, count > 0
}
