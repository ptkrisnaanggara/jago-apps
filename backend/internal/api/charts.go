package api

import (
	"time"

	"github.com/gin-gonic/gin"
	"github.com/ptkrisnaanggara/jago-apps/backend/internal/model"
)

// charts.go provides aggregate data for the dashboard's overview charts.

type chartDaily struct {
	Date    string `json:"date"` // YYYY-MM-DD
	Income  int64  `json:"income"`
	Expense int64  `json:"expense"`
}

type chartCategory struct {
	Category string `json:"category"`
	Total    int64  `json:"total"`
	Count    int64  `json:"count"`
}

type chartsResponse struct {
	Days          int             `json:"days"`
	Daily         []chartDaily    `json:"daily"`
	TopCategories []chartCategory `json:"topCategories"`
}

// getAdminCharts returns a daily income/expense series for the last `?days=`
// (default 14, clamped 1..90) plus the top expense categories.
func (s *Server) getAdminCharts(c *gin.Context) {
	days := atoiDefault(c.Query("days"), 14)
	if days < 1 {
		days = 1
	}
	if days > 90 {
		days = 90
	}

	// Start at midnight `days-1` ago so the window covers `days` calendar days
	// including today.
	now := time.Now()
	startDay := now.AddDate(0, 0, -(days - 1))
	since := time.Date(startDay.Year(), startDay.Month(), startDay.Day(), 0, 0, 0, 0, startDay.Location())

	var rows []chartDaily
	if err := s.db.Model(&model.Transaction{}).
		Select("to_char(date_trunc('day', created_at), 'YYYY-MM-DD') AS date, "+
			"COALESCE(SUM(amount) FILTER (WHERE type = 'income'), 0) AS income, "+
			"COALESCE(SUM(amount) FILTER (WHERE type = 'expense'), 0) AS expense").
		Where("deleted_at IS NULL AND created_at >= ?", since).
		Group("date_trunc('day', created_at)").
		Order("date_trunc('day', created_at)").
		Scan(&rows).Error; err != nil {
		respondError(c, 500, "internal", "failed to load chart data")
		return
	}

	// Fill missing days with zeros so the series is continuous.
	byDate := make(map[string]chartDaily, len(rows))
	for _, r := range rows {
		byDate[r.Date] = r
	}
	daily := make([]chartDaily, 0, days)
	for i := 0; i < days; i++ {
		d := since.AddDate(0, 0, i).Format("2006-01-02")
		if r, ok := byDate[d]; ok {
			daily = append(daily, r)
		} else {
			daily = append(daily, chartDaily{Date: d})
		}
	}

	var cats []chartCategory
	if err := s.db.Model(&model.Transaction{}).
		Select("category, COALESCE(SUM(amount), 0) AS total, COUNT(*) AS count").
		Where("deleted_at IS NULL AND type = 'expense'").
		Group("category").
		Order("total DESC").
		Limit(6).
		Scan(&cats).Error; err != nil {
		respondError(c, 500, "internal", "failed to load chart data")
		return
	}

	respondOK(c, chartsResponse{Days: days, Daily: daily, TopCategories: cats})
}
