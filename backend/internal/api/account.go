package api

import (
	"encoding/json"
	"errors"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/ptkrisnaanggara/jago-apps/backend/internal/model"
	"github.com/redis/go-redis/v9"
)

const accountCacheTTL = 30 * time.Second

func accountCacheKey(userID string) string { return "account:" + userID }

// getAccount returns the user's balance, served from a short-lived Redis cache.
func (s *Server) getAccount(c *gin.Context) {
	uid := currentUserID(c)

	if cached, err := s.rdb.Get(c, accountCacheKey(uid)).Bytes(); err == nil {
		var acct model.Account
		if json.Unmarshal(cached, &acct) == nil {
			c.Header("X-Cache", "HIT")
			respondOK(c, acct)
			return
		}
	}

	var acct model.Account
	if err := s.db.First(&acct, "user_id = ?", uid).Error; err != nil {
		respondError(c, 404, "not_found", "account not found")
		return
	}

	if raw, err := json.Marshal(acct); err == nil {
		s.rdb.Set(c, accountCacheKey(uid), raw, accountCacheTTL)
	}
	c.Header("X-Cache", "MISS")
	respondOK(c, acct)
}

// invalidateAccountCache drops the cached balance after a mutation.
func (s *Server) invalidateAccountCache(c *gin.Context, userID string) {
	if err := s.rdb.Del(c, accountCacheKey(userID)).Err(); err != nil && !errors.Is(err, redis.Nil) {
		// Non-fatal: a stale cache entry simply expires within the TTL.
		_ = err
	}
}
