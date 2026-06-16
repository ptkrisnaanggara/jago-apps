package token

import (
	"testing"
	"time"
)

func TestGenerateAndParse(t *testing.T) {
	m := NewManager("test-secret", time.Hour)

	tok, err := m.Generate("user-123")
	if err != nil {
		t.Fatalf("generate: %v", err)
	}

	sub, err := m.Parse(tok)
	if err != nil {
		t.Fatalf("parse: %v", err)
	}
	if sub != "user-123" {
		t.Fatalf("subject = %q, want %q", sub, "user-123")
	}
}

func TestParseRejectsBadToken(t *testing.T) {
	m := NewManager("test-secret", time.Hour)
	if _, err := m.Parse("not-a-jwt"); err == nil {
		t.Fatal("expected error for malformed token")
	}
}

func TestParseRejectsWrongSecret(t *testing.T) {
	signer := NewManager("secret-a", time.Hour)
	verifier := NewManager("secret-b", time.Hour)

	tok, err := signer.Generate("user-123")
	if err != nil {
		t.Fatalf("generate: %v", err)
	}
	if _, err := verifier.Parse(tok); err == nil {
		t.Fatal("expected error when verifying with a different secret")
	}
}

func TestParseRejectsExpiredToken(t *testing.T) {
	m := NewManager("test-secret", -time.Minute) // already expired
	tok, err := m.Generate("user-123")
	if err != nil {
		t.Fatalf("generate: %v", err)
	}
	if _, err := m.Parse(tok); err == nil {
		t.Fatal("expected error for expired token")
	}
}
