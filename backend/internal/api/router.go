package api

import (
	"net/http"

	"github.com/gin-gonic/gin"
)

// Router builds the Gin engine with all routes.
func (s *Server) Router() *gin.Engine {
	r := gin.New()
	r.Use(gin.Logger(), gin.Recovery())

	r.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{"status": "ok"})
	})

	v1 := r.Group("/api/v1")
	{
		auth := v1.Group("/auth")
		{
			auth.POST("/otp/request", s.requestOTP)
			auth.POST("/otp/verify", s.verifyOTP)
		}

		secured := v1.Group("")
		secured.Use(s.authRequired())
		{
			secured.GET("/me", s.me)

			secured.GET("/account", s.getAccount)
			secured.GET("/pockets", s.listPockets)
			secured.GET("/transactions", s.listTransactions)

			secured.GET("/contacts", s.listContacts)

			secured.GET("/transfers", s.listTransfers)
			secured.POST("/transfers", s.createTransfer)

			secured.GET("/bills", s.listBills)
			secured.POST("/bills", s.createBill)
			secured.POST("/bills/:id/pay", s.payBill)

			secured.GET("/cards", s.listCards)
			secured.POST("/cards/:id/freeze", s.setCardFrozen)

			secured.GET("/notifications", s.listNotifications)
			secured.POST("/notifications/:id/read", s.markNotificationRead)
			secured.POST("/notifications/read-all", s.markAllNotificationsRead)
		}
	}

	return r
}
