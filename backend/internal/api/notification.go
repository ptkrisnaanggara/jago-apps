package api

import (
	"github.com/gin-gonic/gin"
	"github.com/ptkrisnaanggara/jago-apps/backend/internal/model"
)

// listNotifications returns a page of the user's notifications, newest first.
func (s *Server) listNotifications(c *gin.Context) {
	uid := currentUserID(c)
	p := parsePage(c)

	var total int64
	if err := s.db.Model(&model.Notification{}).
		Where("user_id = ?", uid).Count(&total).Error; err != nil {
		respondError(c, 500, "internal", "failed to load notifications")
		return
	}

	var items []model.Notification
	if err := s.db.
		Where("user_id = ?", uid).
		Order("created_at DESC").
		Limit(p.Limit).Offset(p.Offset).
		Find(&items).Error; err != nil {
		respondError(c, 500, "internal", "failed to load notifications")
		return
	}
	respondPaginated(c, items, p, total)
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
