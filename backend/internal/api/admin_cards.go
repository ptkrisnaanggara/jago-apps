package api

import (
	"github.com/gin-gonic/gin"
	"github.com/ptkrisnaanggara/jago-apps/backend/internal/model"
	"gorm.io/gorm"
)

// adminCard is a card joined with its owner's name; the PAN is masked to the
// last four digits (operators never need the full number).
type adminCard struct {
	ID        string `json:"id"`
	UserID    string `json:"userId"`
	UserName  string `json:"userName"`
	Label     string `json:"label"`
	Type      string `json:"type"`
	Number    string `json:"-"` // scanned, then masked into Last4
	Last4     string `json:"last4"`
	IsFrozen  bool   `json:"isFrozen"`
	CreatedAt string `json:"createdAt"`
}

// listAdminCards returns a page of cards across all users with the owner's name,
// newest first. Supports `?page=&limit=` and `?frozen=true|false`.
func (s *Server) listAdminCards(c *gin.Context) {
	p := parsePage(c)

	base := func() *gorm.DB {
		q := s.db.Model(&model.Card{})
		switch c.Query("frozen") {
		case "true":
			q = q.Where("cards.is_frozen = ?", true)
		case "false":
			q = q.Where("cards.is_frozen = ?", false)
		}
		return q
	}

	var total int64
	if err := base().Count(&total).Error; err != nil {
		respondError(c, 500, "internal", "failed to load cards")
		return
	}

	var rows []adminCard
	if err := base().
		Select("cards.id, cards.user_id, users.name AS user_name, cards.label, " +
			"cards.type, cards.number, cards.is_frozen, cards.created_at").
		Joins("LEFT JOIN users ON users.id::text = cards.user_id").
		Where("cards.deleted_at IS NULL").
		Order("cards.created_at DESC").
		Limit(p.Limit).Offset(p.Offset).
		Scan(&rows).Error; err != nil {
		respondError(c, 500, "internal", "failed to load cards")
		return
	}

	for i := range rows {
		rows[i].Last4 = lastFour(rows[i].Number)
		rows[i].Number = ""
	}
	respondPaginated(c, rows, p, total)
}

// lastFour returns the last four digits of a PAN (ignoring spaces).
func lastFour(number string) string {
	digits := make([]rune, 0, len(number))
	for _, r := range number {
		if r >= '0' && r <= '9' {
			digits = append(digits, r)
		}
	}
	if len(digits) <= 4 {
		return string(digits)
	}
	return string(digits[len(digits)-4:])
}
