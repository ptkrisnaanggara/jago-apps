// Package token issues and verifies the API's JWT access tokens.
package token

import (
	"fmt"
	"time"

	"github.com/golang-jwt/jwt/v5"
)

// Manager signs and parses HS256 tokens whose subject is the user ID.
type Manager struct {
	secret []byte
	ttl    time.Duration
}

// NewManager builds a Manager from a secret and token lifetime.
func NewManager(secret string, ttl time.Duration) *Manager {
	return &Manager{secret: []byte(secret), ttl: ttl}
}

// Generate returns a signed token for the given user ID.
func (m *Manager) Generate(userID string) (string, error) {
	now := time.Now()
	claims := jwt.RegisteredClaims{
		Subject:   userID,
		IssuedAt:  jwt.NewNumericDate(now),
		ExpiresAt: jwt.NewNumericDate(now.Add(m.ttl)),
	}
	return jwt.NewWithClaims(jwt.SigningMethodHS256, claims).SignedString(m.secret)
}

// Parse validates a token and returns its subject (user ID).
func (m *Manager) Parse(raw string) (string, error) {
	claims := &jwt.RegisteredClaims{}
	_, err := jwt.ParseWithClaims(raw, claims, func(t *jwt.Token) (any, error) {
		if _, ok := t.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, fmt.Errorf("unexpected signing method: %v", t.Header["alg"])
		}
		return m.secret, nil
	})
	if err != nil {
		return "", err
	}
	if claims.Subject == "" {
		return "", fmt.Errorf("token missing subject")
	}
	return claims.Subject, nil
}
