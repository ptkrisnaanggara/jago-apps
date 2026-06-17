// Command api runs the Jago HTTP API (Gin + GORM/Postgres + Redis + RabbitMQ).
package main

import (
	"context"
	"errors"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/ptkrisnaanggara/jago-apps/backend/internal/api"
	"github.com/ptkrisnaanggara/jago-apps/backend/internal/config"
	"github.com/ptkrisnaanggara/jago-apps/backend/internal/platform/broker"
	"github.com/ptkrisnaanggara/jago-apps/backend/internal/platform/cache"
	"github.com/ptkrisnaanggara/jago-apps/backend/internal/platform/db"
	"github.com/ptkrisnaanggara/jago-apps/backend/internal/platform/logging"
	"github.com/ptkrisnaanggara/jago-apps/backend/internal/token"
)

func main() {
	cfg := config.Load()
	logger := logging.New(cfg.LogLevel, cfg.LogFormat)

	ctx, stop := signal.NotifyContext(context.Background(), syscall.SIGINT, syscall.SIGTERM)
	defer stop()

	gdb, err := db.Open(cfg.DatabaseURL)
	if err != nil {
		logger.Error("postgres connect failed", "error", err)
		os.Exit(1)
	}
	if cfg.MigrateOnStart {
		if err := db.RunMigrations(gdb); err != nil {
			logger.Error("migration failed", "error", err)
			os.Exit(1)
		}
		logger.Info("migrations applied")
	}

	rdb, err := cache.Open(ctx, cfg.RedisURL)
	if err != nil {
		logger.Error("redis connect failed", "error", err)
		os.Exit(1)
	}
	defer func() { _ = rdb.Close() }()

	br, err := broker.Open(cfg.RabbitMQURL)
	if err != nil {
		logger.Error("rabbitmq connect failed", "error", err)
		os.Exit(1)
	}
	defer br.Close()

	tokens := token.NewManager(cfg.JWTSecret, cfg.JWTTTL)
	server := api.New(cfg, gdb, rdb, br, tokens, logger)

	srv := &http.Server{
		Addr:    ":" + cfg.AppPort,
		Handler: server.Router(),
	}

	go func() {
		logger.Info("api listening", "port", cfg.AppPort)
		if err := srv.ListenAndServe(); err != nil && !errors.Is(err, http.ErrServerClosed) {
			logger.Error("listen failed", "error", err)
			os.Exit(1)
		}
	}()

	<-ctx.Done()
	logger.Info("shutting down")

	shutdownCtx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	if err := srv.Shutdown(shutdownCtx); err != nil {
		logger.Error("graceful shutdown failed", "error", err)
	}
}
