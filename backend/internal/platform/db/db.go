// Package db wires GORM to Postgres and applies versioned migrations (goose).
package db

import (
	"fmt"

	"github.com/pressly/goose/v3"
	migrations "github.com/ptkrisnaanggara/jago-apps/backend/migrations"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
	"gorm.io/gorm/logger"
)

// Open connects to Postgres via GORM.
func Open(dsn string) (*gorm.DB, error) {
	gdb, err := gorm.Open(postgres.Open(dsn), &gorm.Config{
		Logger: logger.Default.LogMode(logger.Warn),
	})
	if err != nil {
		return nil, fmt.Errorf("connect postgres: %w", err)
	}
	return gdb, nil
}

// RunMigrations applies all pending migrations (the "migrationsRun: true" path,
// used on API boot). Migrations themselves are the schema source of truth —
// GORM's AutoMigrate is intentionally not used.
func RunMigrations(gdb *gorm.DB) error {
	sqlDB, err := gdb.DB()
	if err != nil {
		return fmt.Errorf("get sql.DB: %w", err)
	}
	goose.SetBaseFS(migrations.FS)
	if err := goose.SetDialect("postgres"); err != nil {
		return fmt.Errorf("set dialect: %w", err)
	}
	if err := goose.Up(sqlDB, "."); err != nil {
		return fmt.Errorf("migrate up: %w", err)
	}
	return nil
}
