package api

import (
	"time"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

// applyDateRange adds inclusive `?from=`/`?to=` (YYYY-MM-DD) filters on the given
// timestamp column. `to` is treated as the whole day (exclusive next-day bound).
// Unparseable or absent bounds are ignored.
func applyDateRange(c *gin.Context, q *gorm.DB, column string) *gorm.DB {
	const layout = "2006-01-02"
	if f := c.Query("from"); f != "" {
		if t, err := time.Parse(layout, f); err == nil {
			q = q.Where(column+" >= ?", t)
		}
	}
	if to := c.Query("to"); to != "" {
		if t, err := time.Parse(layout, to); err == nil {
			q = q.Where(column+" < ?", t.AddDate(0, 0, 1))
		}
	}
	return q
}
