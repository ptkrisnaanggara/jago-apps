package api

import (
	"github.com/gin-gonic/gin"
	"github.com/ptkrisnaanggara/jago-apps/backend/internal/model"
	"gorm.io/gorm"
)

// adminPocket is a pocket (Kantong) joined with its owner's name.
type adminPocket struct {
	ID       string `json:"id"`
	UserID   string `json:"userId"`
	UserName string `json:"userName"`
	Name     string `json:"name"`
	Type     string `json:"type"`
	Balance  int64  `json:"balance"`
	Target   *int64 `json:"target,omitempty"`
	IsMain   bool   `json:"isMain"`
	Locked   bool   `json:"locked"`
	Shared   bool   `json:"shared"`
}

// listAdminPockets returns a page of pockets across all users with the owner's
// name. Supports `?page=&limit=` and `?type=main|spending|saving`.
func (s *Server) listAdminPockets(c *gin.Context) {
	p := parsePage(c)

	base := func() *gorm.DB {
		q := s.db.Model(&model.Pocket{})
		switch model.PocketType(c.Query("type")) {
		case model.PocketMain, model.PocketSpending, model.PocketSaving:
			q = q.Where("pockets.type = ?", c.Query("type"))
		}
		return q
	}

	var total int64
	if err := base().Count(&total).Error; err != nil {
		respondError(c, 500, "internal", "failed to load pockets")
		return
	}

	var rows []adminPocket
	if err := base().
		Select("pockets.id, pockets.user_id, users.name AS user_name, pockets.name, " +
			"pockets.type, pockets.balance, pockets.target, pockets.is_main, " +
			"pockets.locked, pockets.shared").
		Joins("LEFT JOIN users ON users.id::text = pockets.user_id").
		Where("pockets.deleted_at IS NULL").
		Order("pockets.balance DESC").
		Limit(p.Limit).Offset(p.Offset).
		Scan(&rows).Error; err != nil {
		respondError(c, 500, "internal", "failed to load pockets")
		return
	}

	respondPaginated(c, rows, p, total)
}
