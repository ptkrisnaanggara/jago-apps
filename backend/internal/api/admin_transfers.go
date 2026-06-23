package api

import (
	"github.com/gin-gonic/gin"
	"github.com/ptkrisnaanggara/jago-apps/backend/internal/model"
	"gorm.io/gorm"
)

// adminTransfer is a transfer (send-money receipt) joined with the sender's name.
type adminTransfer struct {
	ID               string `json:"id"`
	UserID           string `json:"userId"`
	UserName         string `json:"userName"`
	RecipientName    string `json:"recipientName"`
	RecipientBank    string `json:"recipientBank"`
	RecipientAccount string `json:"recipientAccount"`
	Amount           int64  `json:"amount"`
	Note             string `json:"note"`
	ReferenceID      string `json:"referenceId"`
	CreatedAt        string `json:"createdAt"`
}

// transferBase is the filtered transfer query shared by the list and CSV export
// (`?userId=` + `?from=&to=` date range).
func (s *Server) transferBase(c *gin.Context) *gorm.DB {
	q := s.db.Model(&model.Transfer{})
	if uid := c.Query("userId"); uid != "" {
		q = q.Where("transfers.user_id = ?", uid)
	}
	return applyDateRange(c, q, "transfers.created_at")
}

const transferSelect = "transfers.id, transfers.user_id, users.name AS user_name, " +
	"transfers.recipient_name, transfers.recipient_bank, transfers.recipient_account, " +
	"transfers.amount, transfers.note, transfers.reference_id, transfers.created_at"

// listAdminTransfers returns a page of transfers across all users with the
// sender's name, newest first. Supports `?page=&limit=`, `?userId=`, `?from=&to=`.
func (s *Server) listAdminTransfers(c *gin.Context) {
	p := parsePage(c)

	var total int64
	if err := s.transferBase(c).Count(&total).Error; err != nil {
		respondError(c, 500, "internal", "failed to load transfers")
		return
	}

	var rows []adminTransfer
	if err := s.transferBase(c).
		Select(transferSelect).
		Joins("LEFT JOIN users ON users.id::text = transfers.user_id").
		Where("transfers.deleted_at IS NULL").
		Order("transfers.created_at DESC").
		Limit(p.Limit).Offset(p.Offset).
		Scan(&rows).Error; err != nil {
		respondError(c, 500, "internal", "failed to load transfers")
		return
	}

	respondPaginated(c, rows, p, total)
}
