package api

import (
	"net/http"

	"github.com/gin-gonic/gin"
)

// Router builds the Gin engine with all routes.
func (s *Server) Router() *gin.Engine {
	r := gin.New()
	r.Use(requestID(), s.cors(), s.requestLogger(), gin.CustomRecovery(s.recovery()))

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
			secured.POST("/pockets", s.createPocket)
			secured.POST("/pockets/move", s.movePocket)
			secured.POST("/pockets/:id/lock", s.lockPocket)
			secured.POST("/pockets/:id/unlock", s.unlockPocket)
			secured.POST("/pockets/:id/autosave", s.setAutosave)
			secured.POST("/pockets/:id/autosave/run", s.runAutosave)
			secured.POST("/pockets/:id/share", s.sharePocket)
			secured.GET("/pockets/:id/members", s.listMembers)
			secured.POST("/pockets/:id/deposit", s.depositPocket)
			secured.GET("/transactions", s.listTransactions)

			secured.GET("/contacts", s.listContacts)

			secured.POST("/qris/parse", s.parseQRIS)
			secured.POST("/qris/pay", s.payQRIS)

			secured.GET("/topup/products", s.listTopupProducts)
			secured.POST("/topup", s.purchaseTopup)

			secured.GET("/pools", s.listPools)
			secured.POST("/pools", s.createPool)
			secured.GET("/pools/:id", s.getPool)
			secured.POST("/pools/:id/contribute", s.contributePool)
			secured.POST("/pools/:id/close", s.closePool)

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

		// Admin login (phone + OTP over WhatsApp/WAHA) — public.
		adminAuth := v1.Group("/admin/auth")
		{
			adminAuth.POST("/otp/request", s.requestAdminOTP)
			adminAuth.POST("/otp/verify", s.verifyAdminOTP)
		}

		// Admin dashboard (frontend/) — bearer admin token or static X-Admin-Key.
		admin := v1.Group("/admin")
		admin.Use(s.adminRequired())
		{
			admin.GET("/me", s.adminMe)
			admin.GET("/stats", s.getAdminStats)
			admin.GET("/users", s.listAdminUsers)
			admin.GET("/users/:id", s.getAdminUser)
			admin.PATCH("/users/:id", s.updateAdminUser)
			admin.GET("/transactions", s.listAdminTransactions)
			admin.GET("/pools", s.listAdminPools)
			admin.GET("/audit-logs", s.listAuditLogs)
			admin.POST("/cards/:id/freeze", s.adminSetCardFrozen)

			// CSV exports.
			admin.GET("/export/users", s.exportUsersCSV)
			admin.GET("/export/transactions", s.exportTransactionsCSV)
			admin.GET("/export/audit-logs", s.exportAuditLogsCSV)

			// Admin management (superadmin only).
			admin.GET("/admins", s.listAdmins)
			admin.POST("/admins", s.createAdmin)
			admin.PATCH("/admins/:id", s.updateAdmin)
			admin.POST("/admins/:id/status", s.setAdminStatus)
		}
	}

	return r
}
