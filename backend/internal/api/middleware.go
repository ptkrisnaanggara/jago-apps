package api

import (
	"crypto/subtle"
	"net/http"
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

// cors applies CORS headers so browser clients (the admin dashboard) can call
// the API cross-origin. Auth uses the X-Admin-Key / Authorization headers (not
// cookies), so a wildcard origin is safe; a configured allow-list echoes the
// request's Origin when it matches. Preflight (OPTIONS) is short-circuited.
func (s *Server) cors() gin.HandlerFunc {
	allowAny := false
	allowed := make(map[string]bool, len(s.cfg.CORSAllowedOrigins))
	for _, o := range s.cfg.CORSAllowedOrigins {
		if o == "*" {
			allowAny = true
		}
		allowed[o] = true
	}

	return func(c *gin.Context) {
		origin := c.GetHeader("Origin")
		if origin != "" {
			switch {
			case allowAny:
				c.Header("Access-Control-Allow-Origin", "*")
			case allowed[origin]:
				c.Header("Access-Control-Allow-Origin", origin)
				c.Header("Vary", "Origin")
			}
			c.Header("Access-Control-Allow-Methods", "GET, POST, PUT, PATCH, DELETE, OPTIONS")
			c.Header("Access-Control-Allow-Headers", "Authorization, Content-Type, X-Admin-Key, X-Request-Id")
			c.Header("Access-Control-Max-Age", "600")
		}
		if c.Request.Method == http.MethodOptions {
			c.AbortWithStatus(http.StatusNoContent)
			return
		}
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
