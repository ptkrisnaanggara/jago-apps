package api

import (
	"strconv"

	"github.com/gin-gonic/gin"
)

const (
	defaultPageLimit = 20
	maxPageLimit     = 100
)

// pageQuery is a parsed `?page=&limit=` request.
type pageQuery struct {
	Page   int
	Limit  int
	Offset int
}

// parsePage reads page/limit query params with safe defaults and clamping.
func parsePage(c *gin.Context) pageQuery {
	page := atoiDefault(c.Query("page"), 1)
	if page < 1 {
		page = 1
	}
	limit := atoiDefault(c.Query("limit"), defaultPageLimit)
	if limit < 1 {
		limit = defaultPageLimit
	}
	if limit > maxPageLimit {
		limit = maxPageLimit
	}
	return pageQuery{Page: page, Limit: limit, Offset: (page - 1) * limit}
}

// respondPaginated returns the page of items plus pagination metadata. The
// `data` field stays the array (clients that ignore `meta` still work).
func respondPaginated(c *gin.Context, items any, p pageQuery, total int64) {
	var totalPages int64
	if p.Limit > 0 {
		totalPages = (total + int64(p.Limit) - 1) / int64(p.Limit)
	}
	c.JSON(200, gin.H{
		"data": items,
		"meta": gin.H{
			"page":       p.Page,
			"limit":      p.Limit,
			"total":      total,
			"totalPages": totalPages,
		},
	})
}

func atoiDefault(s string, fallback int) int {
	if s == "" {
		return fallback
	}
	if n, err := strconv.Atoi(s); err == nil {
		return n
	}
	return fallback
}
