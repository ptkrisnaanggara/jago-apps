// Package cache wraps the Redis client.
package cache

import (
	"context"
	"fmt"

	"github.com/redis/go-redis/v9"
)

// Open parses a redis URL and verifies connectivity.
func Open(ctx context.Context, url string) (*redis.Client, error) {
	opt, err := redis.ParseURL(url)
	if err != nil {
		return nil, fmt.Errorf("parse redis url: %w", err)
	}
	client := redis.NewClient(opt)
	if err := client.Ping(ctx).Err(); err != nil {
		return nil, fmt.Errorf("ping redis: %w", err)
	}
	return client, nil
}
