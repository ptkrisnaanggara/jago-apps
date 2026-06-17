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

	// AdminAPIKey guards the /admin endpoints (sent as the X-Admin-Key header).
	// The admin dashboard authenticates with this static key rather than a JWT.
	AdminAPIKey string

	// MigrateOnStart applies pending migrations when the API boots
	// (TypeORM's `migrationsRun: true`). Disable to run them via the CLI.
	MigrateOnStart bool

	OTPTTL      time.Duration
	OTPDemoMode bool   // when true, the OTP is always OTPDemoCode (dev/demo)
	OTPDemoCode string // matches the Flutter app's mock code

	// Rate limiting (Redis-backed).
	OTPMaxRequests       int           // max OTP requests per phone per window
	OTPRateWindow        time.Duration // the request window
	OTPMaxVerifyAttempts int           // max verify attempts per issued OTP

	LogLevel  string // debug | info | warn | error
	LogFormat string // json | text
}

// Load reads configuration, applying sensible local-dev defaults. A `.env`
// file, if present, is loaded first (ignored when absent).
func Load() Config {
	_ = godotenv.Load()

	return Config{
		AppPort:        env("APP_PORT", "8080"),
		DatabaseURL:    env("DATABASE_URL", "postgres://jago:jago@localhost:5432/jago?sslmode=disable"),
		RedisURL:       env("REDIS_URL", "redis://localhost:6379/0"),
		RabbitMQURL:    env("RABBITMQ_URL", "amqp://guest:guest@localhost:5672/"),
		JWTSecret:      env("JWT_SECRET", "change-me-in-production"),
		JWTTTL:         envDuration("JWT_TTL", 24*time.Hour),
		AdminAPIKey:    env("ADMIN_API_KEY", "admin-secret"),
		MigrateOnStart: envBool("MIGRATE_ON_START", true),
		OTPTTL:         envDuration("OTP_TTL", 5*time.Minute),
		OTPDemoMode:    envBool("OTP_DEMO_MODE", true),
		OTPDemoCode:    env("OTP_DEMO_CODE", "123456"),

		OTPMaxRequests:       envInt("OTP_MAX_REQUESTS", 5),
		OTPRateWindow:        envDuration("OTP_RATE_WINDOW", 15*time.Minute),
		OTPMaxVerifyAttempts: envInt("OTP_MAX_VERIFY_ATTEMPTS", 5),

		LogLevel:  env("LOG_LEVEL", "info"),
		LogFormat: env("LOG_FORMAT", "json"),
	}
}

func envInt(key string, fallback int) int {
	if v, ok := os.LookupEnv(key); ok {
		if n, err := strconv.Atoi(v); err == nil {
			return n
		}
	}
	return fallback
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
