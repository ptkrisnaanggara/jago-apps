package api

import "github.com/gin-gonic/gin"

// Responses use a small envelope: `{"data": ...}` on success and
// `{"error": {"code": ..., "message": ...}}` on failure.

func respondOK(c *gin.Context, data any) {
	c.JSON(200, gin.H{"data": data})
}

func respondCreated(c *gin.Context, data any) {
	c.JSON(201, gin.H{"data": data})
}

func respondError(c *gin.Context, status int, code, message string) {
	c.AbortWithStatusJSON(status, gin.H{"error": gin.H{"code": code, "message": message}})
}
