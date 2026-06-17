package api

import (
	"errors"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/ptkrisnaanggara/jago-apps/backend/internal/model"
	"gorm.io/gorm"
	"gorm.io/gorm/clause"
)

// listBills returns a page of the user's bills, earliest due first.
func (s *Server) listBills(c *gin.Context) {
	uid := currentUserID(c)
	p := parsePage(c)

	var total int64
	if err := s.db.Model(&model.Bill{}).
		Where("user_id = ?", uid).Count(&total).Error; err != nil {
		respondError(c, 500, "internal", "failed to load bills")
		return
	}

	var bills []model.Bill
	if err := s.db.
		Where("user_id = ?", uid).
		Order("due_date ASC").
		Limit(p.Limit).Offset(p.Offset).
		Find(&bills).Error; err != nil {
		respondError(c, 500, "internal", "failed to load bills")
		return
	}
	respondPaginated(c, bills, p, total)
}

type createBillRequest struct {
	Biller     string           `json:"biller" binding:"required"`
	Category   string           `json:"category"`
	Amount     int64            `json:"amount" binding:"required,gt=0"`
	DueDate    time.Time        `json:"dueDate" binding:"required"`
	Recurrence model.Recurrence `json:"recurrence"`
}

// createBill schedules a (recurring) bill.
func (s *Server) createBill(c *gin.Context) {
	var req createBillRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		respondError(c, 400, "bad_request", "biller, amount and dueDate are required")
		return
	}
	recurrence := req.Recurrence
	if recurrence == "" {
		recurrence = model.RecurrenceNone
	}
	bill := model.Bill{
		UserID:     currentUserID(c),
		Biller:     req.Biller,
		Category:   req.Category,
		Amount:     req.Amount,
		DueDate:    req.DueDate,
		Recurrence: recurrence,
	}
	if err := s.db.Create(&bill).Error; err != nil {
		respondError(c, 500, "internal", "failed to schedule bill")
		return
	}
	respondCreated(c, bill)
}

// payBill marks a bill paid, debits the account, and records a transaction.
func (s *Server) payBill(c *gin.Context) {
	uid := currentUserID(c)
	id := c.Param("id")
	var bill model.Bill

	err := s.db.Transaction(func(tx *gorm.DB) error {
		if err := tx.First(&bill, "id = ? AND user_id = ?", id, uid).Error; err != nil {
			return err
		}
		if bill.IsPaid {
			return nil // idempotent
		}

		var acct model.Account
		if err := tx.Clauses(clause.Locking{Strength: "UPDATE"}).
			First(&acct, "user_id = ?", uid).Error; err != nil {
			return err
		}
		if acct.Balance < bill.Amount {
			return errInsufficientFunds
		}
		if err := tx.Model(&acct).Update("balance", acct.Balance-bill.Amount).Error; err != nil {
			return err
		}
		if err := tx.Model(&bill).Update("is_paid", true).Error; err != nil {
			return err
		}
		txn := model.Transaction{
			UserID:   uid,
			Title:    bill.Biller,
			Category: "Tagihan",
			Amount:   bill.Amount,
			Type:     model.TxExpense,
		}
		return tx.Create(&txn).Error
	})

	switch {
	case errors.Is(err, gorm.ErrRecordNotFound):
		respondError(c, 404, "not_found", "bill not found")
		return
	case errors.Is(err, errInsufficientFunds):
		respondError(c, 422, "insufficient_funds", "Saldo tidak mencukupi")
		return
	case err != nil:
		respondError(c, 500, "internal", "payment failed")
		return
	}

	s.invalidateAccountCache(c, uid)
	respondOK(c, bill)
}
