// NOCTIS backend entry point.
//
// Boots Fiber, opens Postgres + Redis pools, applies migrations,
// wires HTTP and WebSocket handlers, and waits for SIGINT/SIGTERM
// to shut down gracefully.
package main

import (
	"context"
	"errors"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/rs/zerolog"
	"github.com/rs/zerolog/log"

	"github.com/Sliva2010/APKMES/noctis_backend/internal/auth"
	"github.com/Sliva2010/APKMES/noctis_backend/internal/config"
	"github.com/Sliva2010/APKMES/noctis_backend/internal/messaging"
	"github.com/Sliva2010/APKMES/noctis_backend/internal/storage"
	"github.com/Sliva2010/APKMES/noctis_backend/internal/transport"
)

func main() {
	zerolog.TimeFieldFormat = time.RFC3339Nano
	log.Logger = log.Output(os.Stdout).With().Timestamp().Str("svc", "noctis").Logger()

	cfg, err := config.Load()
	if err != nil {
		log.Fatal().Err(err).Msg("config load failed")
	}
	zerolog.SetGlobalLevel(cfg.LogLevel)

	ctx, cancel := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer cancel()

	pg, err := storage.NewPostgres(ctx, cfg.DatabaseURL)
	if err != nil {
		log.Fatal().Err(err).Msg("postgres connect failed")
	}
	defer pg.Close()

	if err := storage.Migrate(ctx, pg); err != nil {
		log.Fatal().Err(err).Msg("migrations failed")
	}

	rdb, err := storage.NewRedis(ctx, cfg.RedisURL)
	if err != nil {
		log.Fatal().Err(err).Msg("redis connect failed")
	}
	defer func() { _ = rdb.Close() }()

	authSvc := auth.NewService(pg, rdb, cfg.JWTSecret, cfg.SMSProvider)
	msgSvc := messaging.NewService(pg, rdb)

	app := transport.NewServer(transport.Deps{
		Auth:      authSvc,
		Messaging: msgSvc,
		Logger:    &log.Logger,
	})

	addr := ":" + cfg.Port
	go func() {
		log.Info().Str("addr", addr).Msg("noctis backend listening")
		if err := app.Listen(addr); err != nil && !errors.Is(err, http.ErrServerClosed) {
			log.Error().Err(err).Msg("listen failed")
			cancel()
		}
	}()

	<-ctx.Done()
	log.Info().Msg("shutdown signal received")

	shutdownCtx, shutdownCancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer shutdownCancel()
	if err := app.ShutdownWithContext(shutdownCtx); err != nil {
		log.Error().Err(err).Msg("shutdown error")
	}
	log.Info().Msg("noctis backend stopped")
}
