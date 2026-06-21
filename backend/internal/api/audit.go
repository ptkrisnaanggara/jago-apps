package api

import (
	"github.com/gin-gonic/gin"
	"github.com/ptkrisnaanggara/jago-apps/backend/internal/model"
	"gorm.io/gorm"
)

// audit records a privileged admin action. It snapshots the actor (the
// authenticated admin, or "Service Key" for static-key callers) and is
// best-effort: a logging failure never fails the underlying request.
func (s *Server) audit(c *gin.Context, action, targetType, targetID, detail string) {
	actorID := currentAdminID(c)
	actorName := "Service Key"
	if actorID != "" {
		var admin model.AdminUser
		if err := s.db.First(&admin, "id = ?", actorID).Error; err == nil {
			actorName = admin.Name
		}
	}

	entry := model.AuditLog{
		ActorAdminID: actorID,
		ActorName:    actorName,
		Action:       action,
		TargetType:   targetType,
		TargetID:     targetID,
		Detail:       detail,
		IP:           c.ClientIP(),
	}
	if err := s.db.Create(&entry).Error; err != nil {
		s.log.Warn("audit log write failed", "action", action, "error", err)
	}
}

// auditBase builds the filtered audit-log query shared by the list and CSV
// export: `?action=` and `?from=&to=` date range.
func (s *Server) auditBase(c *gin.Context) *gorm.DB {
	q := s.db.Model(&model.AuditLog{})
	if action := c.Query("action"); action != "" {
		q = q.Where("action = ?", action)
	}
	return applyDateRange(c, q, "created_at")
}

// listAuditLogs returns a page of audit entries, newest first. Supports
// `?page=&limit=`, `?action=`, and `?from=&to=` (YYYY-MM-DD).
func (s *Server) listAuditLogs(c *gin.Context) {
	p := parsePage(c)

	var total int64
	if err := s.auditBase(c).Count(&total).Error; err != nil {
		respondError(c, 500, "internal", "failed to load audit logs")
		return
	}

	var logs []model.AuditLog
	if err := s.auditBase(c).
		Order("created_at DESC").
		Limit(p.Limit).Offset(p.Offset).
		Find(&logs).Error; err != nil {
		respondError(c, 500, "internal", "failed to load audit logs")
		return
	}
	respondPaginated(c, logs, p, total)
}
