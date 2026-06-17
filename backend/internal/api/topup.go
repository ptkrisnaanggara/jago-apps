package api

import (
	"errors"
	"fmt"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/ptkrisnaanggara/jago-apps/backend/internal/model"
	"gorm.io/gorm"
	"gorm.io/gorm/clause"
)

// topupProduct is a prepaid product (pulsa / data). Amount is the price paid.
type topupProduct struct {
	ID     string `json:"id"`
	Type   string `json:"type"` // "pulsa" | "data"
	Name   string `json:"name"`
	Amount int64  `json:"amount"`
}

// Static catalog (a real impl would call a biller aggregator).
var topupCatalog = []topupProduct{
	{ID: "pulsa-5", Type: "pulsa", Name: "Pulsa 5.000", Amount: 5_000},
	{ID: "pulsa-10", Type: "pulsa", Name: "Pulsa 10.000", Amount: 10_000},
	{ID: "pulsa-25", Type: "pulsa", Name: "Pulsa 25.000", Amount: 25_000},
	{ID: "pulsa-50", Type: "pulsa", Name: "Pulsa 50.000", Amount: 50_000},
	{ID: "pulsa-100", Type: "pulsa", Name: "Pulsa 100.000", Amount: 100_000},
	{ID: "data-s", Type: "data", Name: "Paket Data 3GB", Amount: 25_000},
	{ID: "data-m", Type: "data", Name: "Paket Data 8GB", Amount: 50_000},
	{ID: "data-l", Type: "data", Name: "Paket Data 20GB", Amount: 95_000},
}

// listTopupProducts returns the prepaid catalog (optionally filtered by ?type=).
func (s *Server) listTopupProducts(c *gin.Context) {
	filter := c.Query("type")
	products := make([]topupProduct, 0, len(topupCatalog))
	for _, p := range topupCatalog {
		if filter == "" || p.Type == filter {
			products = append(products, p)
		}
	}
	respondOK(c, products)
}

type topupRequest struct {
	ProductID string `json:"productId" binding:"required"`
	Phone     string `json:"phone" binding:"required"`
	PocketID  string `json:"pocketId"` // defaults to the main pocket
}

type topupReceipt struct {
	ProductName string    `json:"productName"`
	Type        string    `json:"type"`
	Phone       string    `json:"phone"`
	Amount      int64     `json:"amount"`
	PocketName  string    `json:"pocketName"`
	ReferenceID string    `json:"referenceId"`
	PaidAt      time.Time `json:"paidAt"`
}

// purchaseTopup buys a prepaid product, debiting a pocket and recording a txn.
func (s *Server) purchaseTopup(c *gin.Context) {
	var req topupRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		respondError(c, 400, "bad_request", "productId and phone are required")
		return
	}

	var product *topupProduct
	for i := range topupCatalog {
		if topupCatalog[i].ID == req.ProductID {
			product = &topupCatalog[i]
			break
		}
	}
	if product == nil {
		respondError(c, 404, "not_found", "product not found")
		return
	}

	uid := currentUserID(c)
	category := "Pulsa"
	if product.Type == "data" {
		category = "Paket Data"
	}
	receipt := topupReceipt{
		ProductName: product.Name,
		Type:        product.Type,
		Phone:       req.Phone,
		Amount:      product.Amount,
		ReferenceID: fmt.Sprintf("TP%d", time.Now().UnixMilli()),
		PaidAt:      time.Now(),
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
		if pocket.Balance < product.Amount {
			return errInsufficientFunds
		}
		if err := tx.Model(&pocket).Update("balance", pocket.Balance-product.Amount).Error; err != nil {
			return err
		}
		receipt.PocketName = pocket.Name

		txn := model.Transaction{
			UserID:   uid,
			Title:    product.Name + " · " + req.Phone,
			Category: category,
			Amount:   product.Amount,
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
		respondError(c, 500, "internal", "top-up failed")
		return
	}

	respondCreated(c, receipt)
}
