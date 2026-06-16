// Package db wires GORM to Postgres and runs migrations.
package db

import (
	"fmt"

	"github.com/ptkrisnaanggara/jago-apps/backend/internal/model"
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

// Migrate creates/updates tables for every model.
func Migrate(gdb *gorm.DB) error {
	if err := gdb.AutoMigrate(model.All()...); err != nil {
		return fmt.Errorf("auto-migrate: %w", err)
	}
	return nil
}
