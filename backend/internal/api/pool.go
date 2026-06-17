package api

import (
	"errors"

	"github.com/gin-gonic/gin"
	"github.com/ptkrisnaanggara/jago-apps/backend/internal/model"
	"gorm.io/gorm"
	"gorm.io/gorm/clause"
)

var errPoolClosed = errors.New("pool already closed")

// listPools returns the user's money pools, newest first.
func (s *Server) listPools(c *gin.Context) {
	var pools []model.MoneyPool
	if err := s.db.
		Where("owner_user_id = ?", currentUserID(c)).
		Order("created_at DESC").
		Find(&pools).Error; err != nil {
		respondError(c, 500, "internal", "failed to load pools")
		return
	}
	respondOK(c, pools)
}

type createPoolRequest struct {
	Title  string `json:"title" binding:"required"`
	Target int64  `json:"target" binding:"required,gt=0"`
}

// createPool starts a new (open) money pool.
func (s *Server) createPool(c *gin.Context) {
	var req createPoolRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		respondError(c, 400, "bad_request", "title and a positive target are required")
		return
	}
	pool := model.MoneyPool{
		OwnerUserID: currentUserID(c),
		Title:       req.Title,
		Target:      req.Target,
		Status:      model.PoolOpen,
	}
	if err := s.db.Create(&pool).Error; err != nil {
		respondError(c, 500, "internal", "failed to create pool")
		return
	}
	respondCreated(c, pool)
}

// getPool returns a pool plus its contributions.
func (s *Server) getPool(c *gin.Context) {
	pool, err := s.findPool(c.Param("id"), currentUserID(c))
	if err != nil {
		respondError(c, 404, "not_found", "pool not found")
		return
	}
	var contributions []model.PoolContribution
	if err := s.db.Where("pool_id = ?", pool.ID).
		Order("created_at DESC").Find(&contributions).Error; err != nil {
		respondError(c, 500, "internal", "failed to load contributions")
		return
	}
	respondOK(c, gin.H{"pool": pool, "contributions": contributions})
}

type contributeRequest struct {
	Name   string `json:"name" binding:"required"`
	Amount int64  `json:"amount" binding:"required,gt=0"`
}

// contributePool adds a contribution and bumps the collected total.
func (s *Server) contributePool(c *gin.Context) {
	var req contributeRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		respondError(c, 400, "bad_request", "name and a positive amount are required")
		return
	}

	uid := currentUserID(c)
	id := c.Param("id")
	err := s.db.Transaction(func(tx *gorm.DB) error {
		var pool model.MoneyPool
		if err := tx.Clauses(clause.Locking{Strength: "UPDATE"}).
			First(&pool, "id = ? AND owner_user_id = ?", id, uid).Error; err != nil {
			return err
		}
		if pool.Status != model.PoolOpen {
			return errPoolClosed
		}
		if err := tx.Create(&model.PoolContribution{
			PoolID: pool.ID,
			Name:   req.Name,
			Amount: req.Amount,
		}).Error; err != nil {
			return err
		}
		return tx.Model(&pool).Update("collected", pool.Collected+req.Amount).Error
	})

	switch {
	case errors.Is(err, gorm.ErrRecordNotFound):
		respondError(c, 404, "not_found", "pool not found")
		return
	case errors.Is(err, errPoolClosed):
		respondError(c, 409, "pool_closed", "Patungan sudah ditutup")
		return
	case err != nil:
		respondError(c, 500, "internal", "failed to contribute")
		return
	}
	s.getPool(c)
}

// closePool closes a pool and moves the collected amount to the main pocket.
func (s *Server) closePool(c *gin.Context) {
	uid := currentUserID(c)
	id := c.Param("id")
	var pool model.MoneyPool

	err := s.db.Transaction(func(tx *gorm.DB) error {
		if err := tx.Clauses(clause.Locking{Strength: "UPDATE"}).
			First(&pool, "id = ? AND owner_user_id = ?", id, uid).Error; err != nil {
			return err
		}
		if pool.Status != model.PoolOpen {
			return errPoolClosed
		}
		var main model.Pocket
		if err := tx.Clauses(clause.Locking{Strength: "UPDATE"}).
			First(&main, "user_id = ? AND is_main = ?", uid, true).Error; err != nil {
			return err
		}
		if err := tx.Model(&main).Update("balance", main.Balance+pool.Collected).Error; err != nil {
			return err
		}
		return tx.Model(&pool).Update("status", model.PoolClosed).Error
	})

	switch {
	case errors.Is(err, gorm.ErrRecordNotFound):
		respondError(c, 404, "not_found", "pool not found")
		return
	case errors.Is(err, errPoolClosed):
		respondError(c, 409, "pool_closed", "Patungan sudah ditutup")
		return
	case err != nil:
		respondError(c, 500, "internal", "failed to close pool")
		return
	}
	pool.Status = model.PoolClosed
	respondOK(c, pool)
}

func (s *Server) findPool(id, uid string) (model.MoneyPool, error) {
	var pool model.MoneyPool
	err := s.db.First(&pool, "id = ? AND owner_user_id = ?", id, uid).Error
	return pool, err
}
