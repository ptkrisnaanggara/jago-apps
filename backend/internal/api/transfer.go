package api

import (
	"encoding/json"
	"errors"
	"fmt"
	"log"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/ptkrisnaanggara/jago-apps/backend/internal/event"
	"github.com/ptkrisnaanggara/jago-apps/backend/internal/model"
	"gorm.io/gorm"
	"gorm.io/gorm/clause"
)

var errInsufficientFunds = errors.New("insufficient funds")

type transferRequest struct {
	RecipientName    string `json:"recipientName" binding:"required"`
	RecipientBank    string `json:"recipientBank"`
	RecipientAccount string `json:"recipientAccount"`
	Amount           int64  `json:"amount" binding:"required,gt=0"`
	Note             string `json:"note"`
}

// createTransfer debits the account and records the transfer + a transaction
// atomically (row-locked), then publishes an event for the worker to notify.
func (s *Server) createTransfer(c *gin.Context) {
	var req transferRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		respondError(c, 400, "bad_request", "recipientName and a positive amount are required")
		return
	}

	uid := currentUserID(c)
	var transfer model.Transfer

	err := s.db.Transaction(func(tx *gorm.DB) error {
		var acct model.Account
		if err := tx.Clauses(clause.Locking{Strength: "UPDATE"}).
			First(&acct, "user_id = ?", uid).Error; err != nil {
			return err
		}
		if acct.Balance < req.Amount {
			return errInsufficientFunds
		}
		if err := tx.Model(&acct).Update("balance", acct.Balance-req.Amount).Error; err != nil {
			return err
		}

		transfer = model.Transfer{
			UserID:           uid,
			RecipientName:    req.RecipientName,
			RecipientBank:    req.RecipientBank,
			RecipientAccount: req.RecipientAccount,
			Amount:           req.Amount,
			Note:             req.Note,
			ReferenceID:      fmt.Sprintf("JG%d", time.Now().UnixMilli()),
		}
		if err := tx.Create(&transfer).Error; err != nil {
			return err
		}

		txn := model.Transaction{
			UserID:   uid,
			Title:    "Transfer ke " + req.RecipientName,
			Category: "Kirim & Bayar",
			Amount:   req.Amount,
			Type:     model.TxExpense,
		}
		return tx.Create(&txn).Error
	})

	switch {
	case errors.Is(err, errInsufficientFunds):
		respondError(c, 422, "insufficient_funds", "Saldo tidak mencukupi")
		return
	case err != nil:
		respondError(c, 500, "internal", "transfer failed")
		return
	}

	s.invalidateAccountCache(c, uid)
	s.publishTransferCompleted(c, transfer)
	respondCreated(c, transfer)
}

// listTransfers returns a page of the user's transfer receipts, newest first.
func (s *Server) listTransfers(c *gin.Context) {
	uid := currentUserID(c)
	p := parsePage(c)

	var total int64
	if err := s.db.Model(&model.Transfer{}).
		Where("user_id = ?", uid).Count(&total).Error; err != nil {
		respondError(c, 500, "internal", "failed to load transfers")
		return
	}

	var transfers []model.Transfer
	if err := s.db.
		Where("user_id = ?", uid).
		Order("created_at DESC").
		Limit(p.Limit).Offset(p.Offset).
		Find(&transfers).Error; err != nil {
		respondError(c, 500, "internal", "failed to load transfers")
		return
	}
	respondPaginated(c, transfers, p, total)
}

// publishTransferCompleted emits the event (best-effort: a broker hiccup must
// not fail an already-committed transfer).
func (s *Server) publishTransferCompleted(c *gin.Context, t model.Transfer) {
	if s.broker == nil {
		return
	}
	payload, err := json.Marshal(event.TransferCompleted{
		UserID:        t.UserID,
		TransferID:    t.ID,
		ReferenceID:   t.ReferenceID,
		RecipientName: t.RecipientName,
		Amount:        t.Amount,
	})
	if err != nil {
		return
	}
	if err := s.broker.Publish(c, event.RoutingTransferCompleted, payload); err != nil {
		log.Printf("publish %s failed: %v", event.RoutingTransferCompleted, err)
	}
}
