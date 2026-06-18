// Package waha is a tiny client for WAHA (WhatsApp HTTP API,
// https://waha.devlike.pro) used to deliver admin OTPs over WhatsApp.
package waha

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"strings"
	"time"
)

// Client posts messages to a WAHA server's REST API.
type Client struct {
	baseURL string
	session string
	apiKey  string
	http    *http.Client
}

// New builds a Client. A blank baseURL yields a disabled client (see Enabled).
func New(baseURL, session, apiKey string) *Client {
	if session == "" {
		session = "default"
	}
	return &Client{
		baseURL: strings.TrimRight(baseURL, "/"),
		session: session,
		apiKey:  apiKey,
		http:    &http.Client{Timeout: 10 * time.Second},
	}
}

// Enabled reports whether a WAHA server is configured.
func (c *Client) Enabled() bool { return c.baseURL != "" }

type sendTextRequest struct {
	Session string `json:"session"`
	ChatID  string `json:"chatId"`
	Text    string `json:"text"`
}

// SendText sends a plain-text WhatsApp message to a phone number.
func (c *Client) SendText(ctx context.Context, phone, text string) error {
	if !c.Enabled() {
		return fmt.Errorf("waha: not configured")
	}

	payload := sendTextRequest{
		Session: c.session,
		ChatID:  chatID(phone),
		Text:    text,
	}
	body, err := json.Marshal(payload)
	if err != nil {
		return err
	}

	req, err := http.NewRequestWithContext(ctx, http.MethodPost,
		c.baseURL+"/api/sendText", bytes.NewReader(body))
	if err != nil {
		return err
	}
	req.Header.Set("Content-Type", "application/json")
	if c.apiKey != "" {
		req.Header.Set("X-Api-Key", c.apiKey)
	}

	res, err := c.http.Do(req)
	if err != nil {
		return err
	}
	defer func() { _ = res.Body.Close() }()

	if res.StatusCode < 200 || res.StatusCode >= 300 {
		snippet, _ := io.ReadAll(io.LimitReader(res.Body, 512))
		return fmt.Errorf("waha: send failed (%d): %s", res.StatusCode, strings.TrimSpace(string(snippet)))
	}
	return nil
}

// chatID turns a phone number into a WhatsApp chat id (E.164 digits + @c.us).
// Indonesian local formats are normalized to the 62 country code.
func chatID(phone string) string {
	var digits strings.Builder
	for _, r := range phone {
		if r >= '0' && r <= '9' {
			digits.WriteRune(r)
		}
	}
	n := digits.String()
	switch {
	case strings.HasPrefix(n, "0"):
		n = "62" + strings.TrimPrefix(n, "0")
	case strings.HasPrefix(n, "8"):
		n = "62" + n
	}
	return n + "@c.us"
}
