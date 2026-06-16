package api

import (
	"github.com/gin-gonic/gin"
	"github.com/ptkrisnaanggara/jago-apps/backend/internal/model"
)

// listNotifications returns the user's notifications, newest first.
func (s *Server) listNotifications(c *gin.Context) {
	var items []model.Notification
	if err := s.db.
		Where("user_id = ?", currentUserID(c)).
		Order("created_at DESC").
		Find(&items).Error; err != nil {
		respondError(c, 500, "internal", "failed to load notifications")
		return
	}
	respondOK(c, items)
}

// markNotificationRead marks one notification read.
func (s *Server) markNotificationRead(c *gin.Context) {
	res := s.db.Model(&model.Notification{}).
		Where("id = ? AND user_id = ?", c.Param("id"), currentUserID(c)).
		Update("is_read", true)
	if res.Error != nil {
		respondError(c, 500, "internal", "failed to update notification")
		return
	}
	if res.RowsAffected == 0 {
		respondError(c, 404, "not_found", "notification not found")
		return
	}
	respondOK(c, gin.H{"updated": res.RowsAffected})
}

// markAllNotificationsRead marks every notification read.
func (s *Server) markAllNotificationsRead(c *gin.Context) {
	res := s.db.Model(&model.Notification{}).
		Where("user_id = ? AND is_read = ?", currentUserID(c), false).
		Update("is_read", true)
	if res.Error != nil {
		respondError(c, 500, "internal", "failed to update notifications")
		return
	}
	respondOK(c, gin.H{"updated": res.RowsAffected})
}
