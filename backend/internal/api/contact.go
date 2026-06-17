package api

import (
	"github.com/gin-gonic/gin"
	"github.com/ptkrisnaanggara/jago-apps/backend/internal/model"
)

// listContacts returns a page of the user's saved transfer recipients.
func (s *Server) listContacts(c *gin.Context) {
	uid := currentUserID(c)
	p := parsePage(c)

	var total int64
	if err := s.db.Model(&model.Contact{}).
		Where("user_id = ?", uid).Count(&total).Error; err != nil {
		respondError(c, 500, "internal", "failed to load contacts")
		return
	}

	var contacts []model.Contact
	if err := s.db.
		Where("user_id = ?", uid).
		Order("name ASC").
		Limit(p.Limit).Offset(p.Offset).
		Find(&contacts).Error; err != nil {
		respondError(c, 500, "internal", "failed to load contacts")
		return
	}
	respondPaginated(c, contacts, p, total)
}
