package api

import (
	"strings"

	"github.com/gin-gonic/gin"
)

const ctxUserID = "userID"

// authRequired validates the Bearer token and stores the user ID in context.
func (s *Server) authRequired() gin.HandlerFunc {
	return func(c *gin.Context) {
		header := c.GetHeader("Authorization")
		raw := strings.TrimPrefix(header, "Bearer ")
		if raw == header || raw == "" {
			respondError(c, 401, "unauthorized", "Missing or malformed Authorization header")
			return
		}
		uid, err := s.tokens.Parse(raw)
		if err != nil {
			respondError(c, 401, "unauthorized", "Invalid or expired token")
			return
		}
		c.Set(ctxUserID, uid)
		c.Next()
	}
}

// currentUserID returns the authenticated user's ID (set by authRequired).
func currentUserID(c *gin.Context) string {
	v, _ := c.Get(ctxUserID)
	id, _ := v.(string)
	return id
}
