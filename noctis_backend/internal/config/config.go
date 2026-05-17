// Package config loads NOCTIS settings from environment variables.
//
// Required keys: DATABASE_URL, REDIS_URL, JWT_SECRET.
// Optional keys: PORT (default 8080), LOG_LEVEL (default info),
// SMS_PROVIDER (default mock).
package config

import (
	"errors"
	"fmt"
	"os"
	"strings"

	"github.com/rs/zerolog"
)

type Config struct {
	Port        string
	DatabaseURL string
	RedisURL    string
	JWTSecret   []byte
	LogLevel    zerolog.Level
	SMSProvider string
}

func Load() (Config, error) {
	cfg := Config{
		Port:        getenv("PORT", "8080"),
		DatabaseURL: os.Getenv("DATABASE_URL"),
		RedisURL:    os.Getenv("REDIS_URL"),
		SMSProvider: getenv("SMS_PROVIDER", "mock"),
	}

	secret := os.Getenv("JWT_SECRET")
	if secret == "" {
		secret = os.Getenv("JWT_SECRET_CURRENT")
	}
	cfg.JWTSecret = []byte(secret)

	level, err := zerolog.ParseLevel(getenv("LOG_LEVEL", "info"))
	if err != nil {
		return Config{}, fmt.Errorf("invalid LOG_LEVEL: %w", err)
	}
	cfg.LogLevel = level

	var missing []string
	if cfg.DatabaseURL == "" {
		missing = append(missing, "DATABASE_URL")
	}
	if cfg.RedisURL == "" {
		missing = append(missing, "REDIS_URL")
	}
	if len(cfg.JWTSecret) < 16 {
		missing = append(missing, "JWT_SECRET (>=16 bytes)")
	}
	if len(missing) > 0 {
		return Config{}, errors.New("missing required env: " + strings.Join(missing, ", "))
	}
	return cfg, nil
}

func getenv(key, def string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return def
}
