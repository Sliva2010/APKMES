package storage

import (
	"context"
	"fmt"
	"time"

	"github.com/redis/go-redis/v9"
)

func NewRedis(ctx context.Context, addr string) (*redis.Client, error) {
	opt, err := redis.ParseURL(addr)
	if err != nil {
		return nil, fmt.Errorf("parse redis url: %w", err)
	}
	opt.DialTimeout = 5 * time.Second
	opt.ReadTimeout = 3 * time.Second
	opt.WriteTimeout = 3 * time.Second

	client := redis.NewClient(opt)

	pingCtx, cancel := context.WithTimeout(ctx, 5*time.Second)
	defer cancel()
	if err := client.Ping(pingCtx).Err(); err != nil {
		_ = client.Close()
		return nil, fmt.Errorf("ping redis: %w", err)
	}
	return client, nil
}
