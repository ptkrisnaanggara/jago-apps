// Package api holds the HTTP layer: the Gin router, middleware, and handlers.
package api

import (
	"errors"
	"log/slog"

	"github.com/ptkrisnaanggara/jago-apps/backend/internal/config"
	"github.com/ptkrisnaanggara/jago-apps/backend/internal/model"
	"github.com/ptkrisnaanggara/jago-apps/backend/internal/platform/broker"
	"github.com/ptkrisnaanggara/jago-apps/backend/internal/platform/waha"
	"github.com/ptkrisnaanggara/jago-apps/backend/internal/token"
	"github.com/redis/go-redis/v9"
	"gorm.io/gorm"
)

// Server bundles the dependencies every handler needs.
type Server struct {
	cfg    config.Config
	db     *gorm.DB
	rdb    *redis.Client
	broker *broker.Broker
	tokens *token.Manager
	waha   *waha.Client
	log    *slog.Logger
}

// New constructs a Server.
func New(cfg config.Config, db *gorm.DB, rdb *redis.Client, br *broker.Broker, tokens *token.Manager, logger *slog.Logger) *Server {
	return &Server{
		cfg:    cfg,
		db:     db,
		rdb:    rdb,
		broker: br,
		tokens: tokens,
		waha:   waha.New(cfg.WAHABaseURL, cfg.WAHASession, cfg.WAHAAPIKey),
		log:    logger,
	}
}

// EnsureAdminSeed creates a first admin (from config) when the admin_users
// table is empty, so phone+OTP login works on a fresh database.
func (s *Server) EnsureAdminSeed() error {
	var count int64
	if err := s.db.Model(&model.AdminUser{}).Count(&count).Error; err != nil {
		return err
	}
	if count > 0 {
		return nil
	}
	admin := model.AdminUser{
		Name:   s.cfg.AdminSeedName,
		Phone:  s.cfg.AdminSeedPhone,
		Status: model.AdminActive,
		Role:   "superadmin",
	}
	if err := s.db.Create(&admin).Error; err != nil {
		return err
	}
	s.log.Info("seeded default admin", "phone", admin.Phone, "name", admin.Name)
	return nil
}

// errAdminNotFound is returned when no active admin matches a phone.
var errAdminNotFound = errors.New("admin not found")
