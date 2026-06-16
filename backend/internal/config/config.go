// Package config loads runtime configuration from environment variables.
package config

import (
	"os"
	"strconv"
	"time"

	"github.com/joho/godotenv"
)

// Config holds all runtime settings, sourced from the environment.
type Config struct {
	AppPort     string
	DatabaseURL string
	RedisURL    string
	RabbitMQURL string

	JWTSecret string
	JWTTTL    time.Duration

	// MigrateOnStart applies pending migrations when the API boots
	// (TypeORM's `migrationsRun: true`). Disable to run them via the CLI.
	MigrateOnStart bool

	OTPTTL      time.Duration
	OTPDemoMode bool   // when true, the OTP is always OTPDemoCode (dev/demo)
	OTPDemoCode string // matches the Flutter app's mock code
}

// Load reads configuration, applying sensible local-dev defaults. A `.env`
// file, if present, is loaded first (ignored when absent).
func Load() Config {
	_ = godotenv.Load()

	return Config{
		AppPort:     env("APP_PORT", "8080"),
		DatabaseURL: env("DATABASE_URL", "postgres://jago:jago@localhost:5432/jago?sslmode=disable"),
		RedisURL:    env("REDIS_URL", "redis://localhost:6379/0"),
		RabbitMQURL: env("RABBITMQ_URL", "amqp://guest:guest@localhost:5672/"),
		JWTSecret:      env("JWT_SECRET", "change-me-in-production"),
		JWTTTL:         envDuration("JWT_TTL", 24*time.Hour),
		MigrateOnStart: envBool("MIGRATE_ON_START", true),
		OTPTTL:      envDuration("OTP_TTL", 5*time.Minute),
		OTPDemoMode: envBool("OTP_DEMO_MODE", true),
		OTPDemoCode: env("OTP_DEMO_CODE", "123456"),
	}
}

func env(key, fallback string) string {
	if v, ok := os.LookupEnv(key); ok && v != "" {
		return v
	}
	return fallback
}

func envBool(key string, fallback bool) bool {
	if v, ok := os.LookupEnv(key); ok {
		if b, err := strconv.ParseBool(v); err == nil {
			return b
		}
	}
	return fallback
}

func envDuration(key string, fallback time.Duration) time.Duration {
	if v, ok := os.LookupEnv(key); ok {
		if d, err := time.ParseDuration(v); err == nil {
			return d
		}
	}
	return fallback
}
