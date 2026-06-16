package api

import (
	"github.com/gin-gonic/gin"
	"github.com/ptkrisnaanggara/jago-apps/backend/internal/model"
)

// listContacts returns the user's saved transfer recipients.
func (s *Server) listContacts(c *gin.Context) {
	var contacts []model.Contact
	if err := s.db.
		Where("user_id = ?", currentUserID(c)).
		Order("name ASC").
		Find(&contacts).Error; err != nil {
		respondError(c, 500, "internal", "failed to load contacts")
		return
	}
	respondOK(c, contacts)
}
