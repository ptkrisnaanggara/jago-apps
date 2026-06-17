// Package api holds the HTTP layer: the Gin router, middleware, and handlers.
package api

import (
	"log/slog"

	"github.com/ptkrisnaanggara/jago-apps/backend/internal/config"
	"github.com/ptkrisnaanggara/jago-apps/backend/internal/platform/broker"
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
	log    *slog.Logger
}

// New constructs a Server.
func New(cfg config.Config, db *gorm.DB, rdb *redis.Client, br *broker.Broker, tokens *token.Manager, logger *slog.Logger) *Server {
	return &Server{cfg: cfg, db: db, rdb: rdb, broker: br, tokens: tokens, log: logger}
}
