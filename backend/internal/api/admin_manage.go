package api

import (
	"errors"
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/ptkrisnaanggara/jago-apps/backend/internal/model"
	"gorm.io/gorm"
)

// Admin management (superadmin only): list, create, and enable/disable admins.

// requireSuperadmin allows static-key callers (no admin row) and admins whose
// role is "superadmin"; otherwise it writes 403 and returns false.
func (s *Server) requireSuperadmin(c *gin.Context) bool {
	id := currentAdminID(c)
	if id == "" {
		return true // authenticated via the static service key
	}
	var admin model.AdminUser
	if err := s.db.First(&admin, "id = ?", id).Error; err == nil &&
		admin.Role == "superadmin" {
		return true
	}
	respondError(c, http.StatusForbidden, "forbidden", "Hanya superadmin yang dapat mengelola admin")
	return false
}

// listAdmins returns a page of admin users, newest first.
func (s *Server) listAdmins(c *gin.Context) {
	if !s.requireSuperadmin(c) {
		return
	}
	p := parsePage(c)

	var total int64
	if err := s.db.Model(&model.AdminUser{}).Count(&total).Error; err != nil {
		respondError(c, 500, "internal", "failed to load admins")
		return
	}

	var admins []model.AdminUser
	if err := s.db.
		Order("created_at DESC").
		Limit(p.Limit).Offset(p.Offset).
		Find(&admins).Error; err != nil {
		respondError(c, 500, "internal", "failed to load admins")
		return
	}
	respondPaginated(c, admins, p, total)
}

type createAdminRequest struct {
	Name  string `json:"name" binding:"required"`
	Phone string `json:"phone" binding:"required"`
	Role  string `json:"role"`
}

// createAdmin adds a new (active) admin. Phone must be unique.
func (s *Server) createAdmin(c *gin.Context) {
	if !s.requireSuperadmin(c) {
		return
	}
	var req createAdminRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		respondError(c, 400, "bad_request", "name and phone are required")
		return
	}
	phone := strings.TrimSpace(req.Phone)
	role := req.Role
	if role != "superadmin" {
		role = "admin"
	}

	// Reject a duplicate phone with a clear 409 rather than a DB constraint 500.
	var existing model.AdminUser
	err := s.db.First(&existing, "phone = ?", phone).Error
	if err == nil {
		respondError(c, 409, "conflict", "Nomor HP sudah terdaftar")
		return
	}
	if !errors.Is(err, gorm.ErrRecordNotFound) {
		respondError(c, 500, "internal", "failed to check phone")
		return
	}

	admin := model.AdminUser{
		Name:   strings.TrimSpace(req.Name),
		Phone:  phone,
		Status: model.AdminActive,
		Role:   role,
	}
	if err := s.db.Create(&admin).Error; err != nil {
		respondError(c, 500, "internal", "failed to create admin")
		return
	}
	respondCreated(c, admin)
}

type updateAdminRequest struct {
	Name  *string `json:"name"`
	Phone *string `json:"phone"`
	Role  *string `json:"role"`
}

// updateAdmin edits an admin's name, phone, and/or role. Phone stays unique; a
// superadmin cannot demote their own role (avoids locking themselves out).
func (s *Server) updateAdmin(c *gin.Context) {
	if !s.requireSuperadmin(c) {
		return
	}
	var req updateAdminRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		respondError(c, 400, "bad_request", "invalid body")
		return
	}

	id := c.Param("id")
	var admin model.AdminUser
	if err := s.db.First(&admin, "id = ?", id).Error; err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			respondError(c, 404, "not_found", "admin not found")
			return
		}
		respondError(c, 500, "internal", "failed to load admin")
		return
	}

	updates := map[string]any{}

	if req.Name != nil {
		name := strings.TrimSpace(*req.Name)
		if name == "" {
			respondError(c, 400, "bad_request", "name cannot be empty")
			return
		}
		updates["name"] = name
	}

	if req.Phone != nil {
		phone := strings.TrimSpace(*req.Phone)
		if phone == "" {
			respondError(c, 400, "bad_request", "phone cannot be empty")
			return
		}
		if phone != admin.Phone {
			var clash model.AdminUser
			err := s.db.First(&clash, "phone = ? AND id <> ?", phone, id).Error
			if err == nil {
				respondError(c, 409, "conflict", "Nomor HP sudah terdaftar")
				return
			}
			if !errors.Is(err, gorm.ErrRecordNotFound) {
				respondError(c, 500, "internal", "failed to check phone")
				return
			}
		}
		updates["phone"] = phone
	}

	if req.Role != nil {
		role := *req.Role
		if role != "superadmin" {
			role = "admin"
		}
		if id == currentAdminID(c) && role != "superadmin" {
			respondError(c, 400, "bad_request", "Tidak dapat menurunkan peran sendiri")
			return
		}
		updates["role"] = role
	}

	if len(updates) == 0 {
		respondOK(c, admin) // nothing to change
		return
	}

	if err := s.db.Model(&admin).Updates(updates).Error; err != nil {
		respondError(c, 500, "internal", "failed to update admin")
		return
	}
	s.log.Info("admin_updated", "admin_id", id)
	respondOK(c, admin)
}

type setAdminStatusRequest struct {
	Status string `json:"status" binding:"required"`
}

// setAdminStatus enables/disables an admin. An admin cannot disable themselves
// (avoids locking yourself out of the only session).
func (s *Server) setAdminStatus(c *gin.Context) {
	if !s.requireSuperadmin(c) {
		return
	}
	var req setAdminStatusRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		respondError(c, 400, "bad_request", "status is required")
		return
	}
	status := model.AdminStatus(req.Status)
	if status != model.AdminActive && status != model.AdminDisabled {
		respondError(c, 400, "bad_request", "status must be active or disabled")
		return
	}

	id := c.Param("id")
	if status == model.AdminDisabled && id == currentAdminID(c) {
		respondError(c, 400, "bad_request", "Tidak dapat menonaktifkan akun sendiri")
		return
	}

	res := s.db.Model(&model.AdminUser{}).Where("id = ?", id).
		Update("status", status)
	if res.Error != nil {
		respondError(c, 500, "internal", "failed to update admin")
		return
	}
	if res.RowsAffected == 0 {
		respondError(c, 404, "not_found", "admin not found")
		return
	}

	var admin model.AdminUser
	if err := s.db.First(&admin, "id = ?", id).Error; err != nil {
		respondError(c, 500, "internal", "failed to load admin")
		return
	}
	s.log.Info("admin_status_changed", "admin_id", id, "status", status)
	respondOK(c, admin)
}
