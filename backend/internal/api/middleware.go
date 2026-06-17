package api

import (
	"crypto/subtle"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

const (
	ctxUserID       = "userID"
	ctxRequestID    = "requestID"
	headerRequestID = "X-Request-Id"
)

// requestID assigns (or echoes) a request ID, stored in context and returned in
// the response header so logs and clients can correlate a request.
func requestID() gin.HandlerFunc {
	return func(c *gin.Context) {
		id := c.GetHeader(headerRequestID)
		if id == "" {
			id = uuid.NewString()
		}
		c.Set(ctxRequestID, id)
		c.Header(headerRequestID, id)
		c.Next()
	}
}

// requestLogger emits one structured log line per request (level by status).
func (s *Server) requestLogger() gin.HandlerFunc {
	return func(c *gin.Context) {
		start := time.Now()
		c.Next()

		status := c.Writer.Status()
		attrs := []any{
			"request_id", c.GetString(ctxRequestID),
			"method", c.Request.Method,
			"path", c.Request.URL.Path,
			"status", status,
			"latency_ms", time.Since(start).Milliseconds(),
			"ip", c.ClientIP(),
		}
		switch {
		case status >= 500:
			s.log.Error("http_request", attrs...)
		case status >= 400:
			s.log.Warn("http_request", attrs...)
		default:
			s.log.Info("http_request", attrs...)
		}
	}
}

// recovery logs a panic with its request ID and returns a 500.
func (s *Server) recovery() gin.RecoveryFunc {
	return func(c *gin.Context, err any) {
		s.log.Error("panic_recovered",
			"request_id", c.GetString(ctxRequestID),
			"path", c.Request.URL.Path,
			"error", err,
		)
		respondError(c, 500, "internal", "internal server error")
	}
}

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

// adminRequired guards the admin dashboard endpoints with a static API key
// sent in the X-Admin-Key header (configured via ADMIN_API_KEY). It uses a
// constant-time comparison so the check does not leak the key by timing.
func (s *Server) adminRequired() gin.HandlerFunc {
	want := []byte(s.cfg.AdminAPIKey)
	return func(c *gin.Context) {
		got := []byte(c.GetHeader("X-Admin-Key"))
		if len(want) == 0 || subtle.ConstantTimeCompare(got, want) != 1 {
			respondError(c, 401, "unauthorized", "Invalid or missing admin key")
			return
		}
		c.Next()
	}
}

// currentUserID returns the authenticated user's ID (set by authRequired).
func currentUserID(c *gin.Context) string {
	v, _ := c.Get(ctxUserID)
	id, _ := v.(string)
	return id
}
