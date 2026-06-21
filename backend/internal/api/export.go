package api

import (
	"encoding/csv"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/ptkrisnaanggara/jago-apps/backend/internal/model"
)

// CSV export of the admin tables. Each endpoint streams up to exportMaxRows rows
// (newest first) as an attachment. Auth is the usual admin bearer/key.

const exportMaxRows = 50000

// csvDownload sets attachment headers and returns a writer the caller fills.
func csvDownload(c *gin.Context, filename string) *csv.Writer {
	stamp := time.Now().Format("20060102-150405")
	c.Header("Content-Type", "text/csv; charset=utf-8")
	c.Header("Content-Disposition", "attachment; filename=\""+filename+"-"+stamp+".csv\"")
	return csv.NewWriter(c.Writer)
}

func itoa(n int64) string { return strconv.FormatInt(n, 10) }

// exportUsersCSV streams users joined with their account balance.
func (s *Server) exportUsersCSV(c *gin.Context) {
	var rows []adminUser
	if err := s.db.Model(&model.User{}).
		Select("users.id, users.name, users.phone, users.kyc_status, users.status, " +
			"users.created_at, accounts.account_number, COALESCE(accounts.balance, 0) AS balance").
		Joins("LEFT JOIN accounts ON accounts.user_id = users.id::text AND accounts.deleted_at IS NULL").
		Where("users.deleted_at IS NULL").
		Order("users.created_at DESC").
		Limit(exportMaxRows).
		Scan(&rows).Error; err != nil {
		respondError(c, 500, "internal", "failed to export users")
		return
	}

	w := csvDownload(c, "users")
	defer w.Flush()
	_ = w.Write([]string{"id", "name", "phone", "kycStatus", "status", "accountNumber", "balance", "createdAt"})
	for _, u := range rows {
		_ = w.Write([]string{
			u.ID, u.Name, u.Phone, u.KYCStatus, u.Status, u.AccountNumber, itoa(u.Balance), u.CreatedAt,
		})
	}
}

// exportTransactionsCSV streams transactions across all users with owner name.
func (s *Server) exportTransactionsCSV(c *gin.Context) {
	var rows []adminTransaction
	if err := s.db.Model(&model.Transaction{}).
		Select("transactions.id, transactions.user_id, users.name AS user_name, " +
			"transactions.title, transactions.category, transactions.amount, " +
			"transactions.type, transactions.created_at").
		Joins("LEFT JOIN users ON users.id::text = transactions.user_id").
		Where("transactions.deleted_at IS NULL").
		Order("transactions.created_at DESC").
		Limit(exportMaxRows).
		Scan(&rows).Error; err != nil {
		respondError(c, 500, "internal", "failed to export transactions")
		return
	}

	w := csvDownload(c, "transactions")
	defer w.Flush()
	_ = w.Write([]string{"id", "userId", "userName", "title", "category", "amount", "type", "createdAt"})
	for _, t := range rows {
		_ = w.Write([]string{
			t.ID, t.UserID, t.UserName, t.Title, t.Category, itoa(t.Amount), t.Type, t.CreatedAt,
		})
	}
}

// exportAuditLogsCSV streams the audit log.
func (s *Server) exportAuditLogsCSV(c *gin.Context) {
	var logs []model.AuditLog
	if err := s.db.
		Order("created_at DESC").
		Limit(exportMaxRows).
		Find(&logs).Error; err != nil {
		respondError(c, 500, "internal", "failed to export audit logs")
		return
	}

	w := csvDownload(c, "audit-logs")
	defer w.Flush()
	_ = w.Write([]string{"id", "createdAt", "actorName", "action", "targetType", "targetId", "detail", "ip"})
	for _, e := range logs {
		_ = w.Write([]string{
			e.ID, e.CreatedAt.Format(time.RFC3339), e.ActorName, e.Action,
			e.TargetType, e.TargetID, e.Detail, e.IP,
		})
	}
}
