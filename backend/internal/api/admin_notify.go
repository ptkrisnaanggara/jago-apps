package api

import (
	"errors"
	"fmt"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/ptkrisnaanggara/jago-apps/backend/internal/model"
	"gorm.io/gorm"
)

type sendNotificationRequest struct {
	UserID   string `json:"userId"` // optional; empty broadcasts to all users
	Title    string `json:"title" binding:"required"`
	Body     string `json:"body" binding:"required"`
	Category string `json:"category"`
}

// sendAdminNotification creates an in-app notification for a single user (when
// userId is set) or broadcasts to every user. Audited as notification.send.
func (s *Server) sendAdminNotification(c *gin.Context) {
	var req sendNotificationRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		respondError(c, 400, "bad_request", "title and body are required")
		return
	}
	title := strings.TrimSpace(req.Title)
	body := strings.TrimSpace(req.Body)
	if title == "" || body == "" {
		respondError(c, 400, "bad_request", "title and body are required")
		return
	}

	category := model.NotificationCategory(req.Category)
	switch category {
	case model.NotifInfo, model.NotifPromo, model.NotifSecurity:
	case "":
		category = model.NotifInfo
	default:
		respondError(c, 400, "bad_request", "invalid category")
		return
	}

	// Resolve the target user IDs.
	var ids []string
	if req.UserID != "" {
		var user model.User
		if err := s.db.First(&user, "id = ?", req.UserID).Error; err != nil {
			if errors.Is(err, gorm.ErrRecordNotFound) {
				respondError(c, 404, "not_found", "user not found")
				return
			}
			respondError(c, 500, "internal", "failed to load user")
			return
		}
		ids = []string{user.ID}
	} else if err := s.db.Model(&model.User{}).Pluck("id", &ids).Error; err != nil {
		respondError(c, 500, "internal", "failed to load users")
		return
	}

	if len(ids) == 0 {
		respondOK(c, gin.H{"count": 0})
		return
	}

	notifs := make([]model.Notification, 0, len(ids))
	for _, uid := range ids {
		notifs = append(notifs, model.Notification{
			UserID:   uid,
			Title:    title,
			Body:     body,
			Category: category,
		})
	}
	if err := s.db.CreateInBatches(notifs, 500).Error; err != nil {
		respondError(c, 500, "internal", "failed to send notifications")
		return
	}

	scope := fmt.Sprintf("%d pengguna", len(ids))
	if req.UserID == "" {
		scope = fmt.Sprintf("semua pengguna (%d)", len(ids))
	}
	s.audit(c, "notification.send", "notification", req.UserID,
		fmt.Sprintf("Kirim notifikasi \"%s\" ke %s", title, scope))

	respondOK(c, gin.H{"count": len(ids)})
}
