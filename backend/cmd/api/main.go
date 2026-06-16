// Command api runs the Jago HTTP API (Gin + GORM/Postgres + Redis + RabbitMQ).
package main

import (
	"context"
	"errors"
	"log"
	"net/http"
	"os/signal"
	"syscall"
	"time"

	"github.com/ptkrisnaanggara/jago-apps/backend/internal/api"
	"github.com/ptkrisnaanggara/jago-apps/backend/internal/config"
	"github.com/ptkrisnaanggara/jago-apps/backend/internal/platform/broker"
	"github.com/ptkrisnaanggara/jago-apps/backend/internal/platform/cache"
	"github.com/ptkrisnaanggara/jago-apps/backend/internal/platform/db"
	"github.com/ptkrisnaanggara/jago-apps/backend/internal/token"
)

func main() {
	cfg := config.Load()

	ctx, stop := signal.NotifyContext(context.Background(), syscall.SIGINT, syscall.SIGTERM)
	defer stop()

	gdb, err := db.Open(cfg.DatabaseURL)
	if err != nil {
		log.Fatalf("postgres: %v", err)
	}
	if err := db.Migrate(gdb); err != nil {
		log.Fatalf("migrate: %v", err)
	}

	rdb, err := cache.Open(ctx, cfg.RedisURL)
	if err != nil {
		log.Fatalf("redis: %v", err)
	}
	defer func() { _ = rdb.Close() }()

	br, err := broker.Open(cfg.RabbitMQURL)
	if err != nil {
		log.Fatalf("rabbitmq: %v", err)
	}
	defer br.Close()

	tokens := token.NewManager(cfg.JWTSecret, cfg.JWTTTL)
	server := api.New(cfg, gdb, rdb, br, tokens)

	srv := &http.Server{
		Addr:    ":" + cfg.AppPort,
		Handler: server.Router(),
	}

	go func() {
		log.Printf("API listening on :%s", cfg.AppPort)
		if err := srv.ListenAndServe(); err != nil && !errors.Is(err, http.ErrServerClosed) {
			log.Fatalf("listen: %v", err)
		}
	}()

	<-ctx.Done()
	log.Println("shutting down...")

	shutdownCtx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	if err := srv.Shutdown(shutdownCtx); err != nil {
		log.Printf("graceful shutdown failed: %v", err)
	}
}
