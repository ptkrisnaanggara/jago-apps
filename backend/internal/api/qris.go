package api

import (
	"errors"
	"fmt"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/ptkrisnaanggara/jago-apps/backend/internal/model"
	"github.com/ptkrisnaanggara/jago-apps/backend/internal/qris"
	"gorm.io/gorm"
	"gorm.io/gorm/clause"
)

type qrisParseRequest struct {
	Payload string `json:"payload" binding:"required"`
}

// parseQRIS decodes a QRIS payload into merchant + amount info.
func (s *Server) parseQRIS(c *gin.Context) {
	var req qrisParseRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		respondError(c, 400, "bad_request", "payload is required")
		return
	}
	respondOK(c, qris.Parse(req.Payload))
}

type qrisPayRequest struct {
	Payload  string `json:"payload" binding:"required"`
	PocketID string `json:"pocketId"` // defaults to the main pocket
	Amount   int64  `json:"amount"`   // used only for dynamic QRs (no embedded amount)
}

type qrisReceipt struct {
	MerchantName string    `json:"merchantName"`
	MerchantCity string    `json:"merchantCity"`
	Amount       int64     `json:"amount"`
	PocketName   string    `json:"pocketName"`
	ReferenceID  string    `json:"referenceId"`
	PaidAt       time.Time `json:"paidAt"`
}

// payQRIS pays a QRIS merchant from one of the user's pockets.
func (s *Server) payQRIS(c *gin.Context) {
	var req qrisPayRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		respondError(c, 400, "bad_request", "payload is required")
		return
	}

	info := qris.Parse(req.Payload)
	amount := info.Amount
	if !info.Dynamic {
		amount = req.Amount // amount not embedded in the QR → caller supplies it
	}
	if amount <= 0 {
		respondError(c, 400, "bad_request", "a positive amount is required")
		return
	}

	uid := currentUserID(c)
	receipt := qrisReceipt{
		MerchantName: info.MerchantName,
		MerchantCity: info.MerchantCity,
		Amount:       amount,
		ReferenceID:  fmt.Sprintf("QR%d", time.Now().UnixMilli()),
		PaidAt:       time.Now(),
	}

	err := s.db.Transaction(func(tx *gorm.DB) error {
		q := tx.Clauses(clause.Locking{Strength: "UPDATE"}).Where("user_id = ?", uid)
		if req.PocketID != "" {
			q = q.Where("id = ?", req.PocketID)
		} else {
			q = q.Where("is_main = ?", true)
		}
		var pocket model.Pocket
		if err := q.First(&pocket).Error; err != nil {
			return err
		}
		if pocket.Balance < amount {
			return errInsufficientFunds
		}
		if err := tx.Model(&pocket).Update("balance", pocket.Balance-amount).Error; err != nil {
			return err
		}
		receipt.PocketName = pocket.Name

		txn := model.Transaction{
			UserID:   uid,
			Title:    "QRIS - " + info.MerchantName,
			Category: "QRIS",
			Amount:   amount,
			Type:     model.TxExpense,
		}
		return tx.Create(&txn).Error
	})

	switch {
	case errors.Is(err, gorm.ErrRecordNotFound):
		respondError(c, 404, "not_found", "pocket not found")
		return
	case errors.Is(err, errInsufficientFunds):
		respondError(c, 422, "insufficient_funds", "Saldo kantong tidak mencukupi")
		return
	case err != nil:
		respondError(c, 500, "internal", "qris payment failed")
		return
	}

	respondCreated(c, receipt)
}
