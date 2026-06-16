// Command migrate is the database migration CLI (goose), the analog of
// TypeORM's `migration:run` / `migration:revert` / `migration:show`.
//
//	go run ./cmd/migrate up                 # apply all pending      (migration:run)
//	go run ./cmd/migrate down               # revert the last        (migration:revert)
//	go run ./cmd/migrate status             # list applied/pending   (migration:show)
//	go run ./cmd/migrate version            # current version
//	go run ./cmd/migrate reset              # revert everything
//	go run ./cmd/migrate redo               # down + up the last
//	go run ./cmd/migrate create <name> sql  # scaffold a new migration  (migration:create)
package main

import (
	"context"
	"log"
	"os"

	"github.com/pressly/goose/v3"
	"github.com/ptkrisnaanggara/jago-apps/backend/internal/config"
	migrations "github.com/ptkrisnaanggara/jago-apps/backend/migrations"
	"github.com/ptkrisnaanggara/jago-apps/backend/internal/platform/db"
)

const migrationsDir = "migrations"

func main() {
	if len(os.Args) < 2 {
		log.Fatal("usage: migrate <up|down|status|version|reset|redo|create> [args...]")
	}
	command := os.Args[1]
	args := os.Args[2:]

	cfg := config.Load()
	gdb, err := db.Open(cfg.DatabaseURL)
	if err != nil {
		log.Fatalf("postgres: %v", err)
	}
	sqlDB, err := gdb.DB()
	if err != nil {
		log.Fatalf("sql.DB: %v", err)
	}
	if err := goose.SetDialect("postgres"); err != nil {
		log.Fatalf("dialect: %v", err)
	}

	ctx := context.Background()

	// `create` writes a new file to disk, so it uses the on-disk dir; every
	// other command reads the embedded migrations.
	if command == "create" {
		if err := goose.RunContext(ctx, "create", sqlDB, migrationsDir, args...); err != nil {
			log.Fatalf("create: %v", err)
		}
		return
	}

	goose.SetBaseFS(migrations.FS)
	if err := goose.RunContext(ctx, command, sqlDB, ".", args...); err != nil {
		log.Fatalf("%s: %v", command, err)
	}
}
