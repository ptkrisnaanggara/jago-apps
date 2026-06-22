package api

import (
	"errors"
	"fmt"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/ptkrisnaanggara/jago-apps/backend/internal/model"
	"gorm.io/gorm"
	"gorm.io/gorm/clause"
)

var errInsufficientBalance = errors.New("insufficient balance")

type adjustBalanceRequest struct {
	Type   string `json:"type" binding:"required"` // credit | debit
	Amount int64  `json:"amount" binding:"required,gt=0"`
	Reason string `json:"reason" binding:"required"`
}

// adjustUserBalance credits or debits a user's account balance by an operator,
// recording a matching transaction (so it appears in history/charts) and an
// audit entry. Runs in a row-locked DB transaction.
func (s *Server) adjustUserBalance(c *gin.Context) {
	var req adjustBalanceRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		respondError(c, 400, "bad_request", "type, positive amount, and reason are required")
		return
	}
	if req.Type != "credit" && req.Type != "debit" {
		respondError(c, 400, "bad_request", "type must be credit or debit")
		return
	}

	id := c.Param("id")
	reason := strings.TrimSpace(req.Reason)
	if reason == "" {
		respondError(c, 400, "bad_request", "reason is required")
		return
	}

	var acct model.Account
	err := s.db.Transaction(func(tx *gorm.DB) error {
		if err := tx.Clauses(clause.Locking{Strength: "UPDATE"}).
			First(&acct, "user_id = ?", id).Error; err != nil {
			return err
		}

		delta := req.Amount
		txType := model.TxIncome
		if req.Type == "debit" {
			if acct.Balance < req.Amount {
				return errInsufficientBalance
			}
			delta = -req.Amount
			txType = model.TxExpense
		}

		if err := tx.Model(&acct).Update("balance", acct.Balance+delta).Error; err != nil {
			return err
		}
		acct.Balance += delta

		return tx.Create(&model.Transaction{
			UserID:   id,
			Title:    "Penyesuaian Admin: " + reason,
			Category: "Penyesuaian",
			Amount:   req.Amount,
			Type:     txType,
		}).Error
	})

	switch {
	case errors.Is(err, gorm.ErrRecordNotFound):
		respondError(c, 404, "not_found", "account not found")
		return
	case errors.Is(err, errInsufficientBalance):
		respondError(c, 400, "insufficient_balance", "Saldo tidak mencukupi untuk debit")
		return
	case err != nil:
		respondError(c, 500, "internal", "failed to adjust balance")
		return
	}

	s.invalidateAccountCache(c, id)

	verb := "Kredit"
	if req.Type == "debit" {
		verb = "Debit"
	}
	s.audit(c, "account.adjust", "user", id,
		fmt.Sprintf("%s Rp%d — %s", verb, req.Amount, reason))
	respondOK(c, acct)
}
