// Package model defines the GORM-mapped domain entities. Monetary amounts are
// whole Rupiah stored as int64 (the IDR has no minor unit in practice).
package model

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

// Base carries a UUID primary key and timestamps shared by every entity.
type Base struct {
	ID        string         `gorm:"type:uuid;primaryKey" json:"id"`
	CreatedAt time.Time      `json:"createdAt"`
	UpdatedAt time.Time      `json:"updatedAt"`
	DeletedAt gorm.DeletedAt `gorm:"index" json:"-"`
}

// BeforeCreate assigns a UUID when one was not provided.
func (b *Base) BeforeCreate(*gorm.DB) error {
	if b.ID == "" {
		b.ID = uuid.NewString()
	}
	return nil
}

// User is an authenticated account holder (phone is the login identity).
type User struct {
	Base
	Name  string `gorm:"not null" json:"name"`
	Phone string `gorm:"uniqueIndex;not null" json:"phone"`
}

// Account is the user's primary balance (one per user).
type Account struct {
	Base
	UserID        string `gorm:"uniqueIndex;not null" json:"userId"`
	HolderName    string `json:"holderName"`
	AccountNumber string `json:"accountNumber"`
	Balance       int64  `json:"balance"`
}

// Pocket is a savings "Kantong" with an optional target.
type Pocket struct {
	Base
	UserID  string `gorm:"index;not null" json:"userId"`
	Name    string `json:"name"`
	Balance int64  `json:"balance"`
	Target  *int64 `json:"target,omitempty"`
	IsMain  bool   `json:"isMain"`
}

// TxType distinguishes money in vs money out.
type TxType string

const (
	TxIncome  TxType = "income"
	TxExpense TxType = "expense"
)

// Transaction is a single money movement in the history.
type Transaction struct {
	Base
	UserID   string `gorm:"index;not null" json:"userId"`
	Title    string `json:"title"`
	Category string `json:"category"`
	Amount   int64  `json:"amount"`
	Type     TxType `json:"type"`
}

// Transfer is a completed send-money operation (its receipt).
type Transfer struct {
	Base
	UserID           string `gorm:"index;not null" json:"userId"`
	RecipientName    string `json:"recipientName"`
	RecipientBank    string `json:"recipientBank"`
	RecipientAccount string `json:"recipientAccount"`
	Amount           int64  `json:"amount"`
	Note             string `json:"note"`
	ReferenceID      string `gorm:"uniqueIndex" json:"referenceId"`
}

// Recurrence mirrors the app's bill frequency.
type Recurrence string

const (
	RecurrenceNone    Recurrence = "none"
	RecurrenceWeekly  Recurrence = "weekly"
	RecurrenceMonthly Recurrence = "monthly"
)

// Bill is a scheduled bill / payment plan.
type Bill struct {
	Base
	UserID     string     `gorm:"index;not null" json:"userId"`
	Biller     string     `json:"biller"`
	Category   string     `json:"category"`
	Amount     int64      `json:"amount"`
	DueDate    time.Time  `json:"dueDate"`
	IsPaid     bool       `json:"isPaid"`
	Recurrence Recurrence `json:"recurrence"`
}

// CardType distinguishes virtual vs physical cards.
type CardType string

const (
	CardVirtual  CardType = "virtual"
	CardPhysical CardType = "physical"
)

// Card is a payment card. The PAN/CVV are demo data only.
type Card struct {
	Base
	UserID     string   `gorm:"index;not null" json:"userId"`
	Label      string   `json:"label"`
	Number     string   `json:"number"`
	HolderName string   `json:"holderName"`
	Expiry     string   `json:"expiry"`
	CVV        string   `json:"cvv"`
	Type       CardType `json:"type"`
	IsFrozen   bool     `json:"isFrozen"`
}

// NotificationCategory groups notifications for display.
type NotificationCategory string

const (
	NotifTransaction NotificationCategory = "transaction"
	NotifPromo       NotificationCategory = "promo"
	NotifSecurity    NotificationCategory = "security"
	NotifInfo        NotificationCategory = "info"
)

// Notification is an in-app notification.
type Notification struct {
	Base
	UserID   string               `gorm:"index;not null" json:"userId"`
	Title    string               `json:"title"`
	Body     string               `json:"body"`
	Category NotificationCategory `json:"category"`
	IsRead   bool                 `json:"isRead"`
}

// Contact is a saved transfer recipient / payee shown in the picker.
type Contact struct {
	Base
	UserID        string `gorm:"index;not null" json:"userId"`
	Name          string `json:"name"`
	BankName      string `json:"bankName"`
	AccountNumber string `json:"accountNumber"`
}

// All returns every model for AutoMigrate.
func All() []any {
	return []any{
		&User{}, &Account{}, &Pocket{}, &Transaction{},
		&Transfer{}, &Bill{}, &Card{}, &Notification{}, &Contact{},
	}
}
