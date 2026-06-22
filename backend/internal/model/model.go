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

// KYCStatus tracks a user's identity-verification state.
type KYCStatus string

const (
	KYCNone     KYCStatus = "none"
	KYCPending  KYCStatus = "pending"
	KYCVerified KYCStatus = "verified"
	KYCRejected KYCStatus = "rejected"
)

// UserStatus is an account's access state.
type UserStatus string

const (
	UserActive  UserStatus = "active"
	UserBlocked UserStatus = "blocked"
)

// User is an authenticated account holder (phone is the login identity).
type User struct {
	Base
	Name      string     `gorm:"not null" json:"name"`
	Phone     string     `gorm:"uniqueIndex;not null" json:"phone"`
	KYCStatus KYCStatus  `gorm:"not null;default:none" json:"kycStatus"`
	Status    UserStatus `gorm:"not null;default:active" json:"status"`
}

// Account is the user's primary balance (one per user).
type Account struct {
	Base
	UserID        string `gorm:"uniqueIndex;not null" json:"userId"`
	HolderName    string `json:"holderName"`
	AccountNumber string `json:"accountNumber"`
	Balance       int64  `json:"balance"`
}

// PocketType mirrors Jago's pocket kinds.
type PocketType string

const (
	PocketMain     PocketType = "main"
	PocketSpending PocketType = "spending"
	PocketSaving   PocketType = "saving"
)

// Pocket is a "Kantong" with an optional savings target.
type Pocket struct {
	Base
	UserID  string     `gorm:"index;not null" json:"userId"`
	Name    string     `json:"name"`
	Type    PocketType `json:"type"`
	Balance int64      `json:"balance"`
	Target  *int64     `json:"target,omitempty"`
	IsMain  bool       `json:"isMain"`

	// Saving lock: while locked, money cannot be moved out of the pocket.
	Locked    bool       `json:"locked"`
	LockUntil *time.Time `json:"lockUntil,omitempty"`

	// Autosave: a recurring top-up from the main pocket. AutosaveAmount == 0
	// means autosave is off. Frequency is none|daily|weekly|monthly.
	AutosaveAmount    int64  `json:"autosaveAmount"`
	AutosaveFrequency string `json:"autosaveFrequency"`

	// Shared (Kantong Bersama): true once shared with another user.
	Shared bool `json:"shared"`

	// Role is the requesting user's role for this pocket ("owner"/"member").
	// Computed per-request, not persisted.
	Role string `gorm:"-" json:"role,omitempty"`
}

// PocketMember links an additional user to a shared pocket.
type PocketMember struct {
	Base
	PocketID string `gorm:"index;not null" json:"pocketId"`
	UserID   string `gorm:"index;not null" json:"userId"`
	Role     string `json:"role"` // owner | member
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

// AdminStatus is an admin account's lifecycle state.
type AdminStatus string

const (
	AdminActive   AdminStatus = "active"
	AdminDisabled AdminStatus = "disabled"
)

// AdminUser is a dashboard operator. Login is phone + OTP (delivered over
// WhatsApp via WAHA); only `active` admins may sign in.
type AdminUser struct {
	Base
	Name   string      `gorm:"not null" json:"name"`
	Phone  string      `gorm:"uniqueIndex;not null" json:"phone"`
	Status AdminStatus `gorm:"not null;default:active" json:"status"`
	Role   string      `json:"role"` // admin | superadmin
}

// AuditLog records a privileged admin action for accountability. Actor fields
// snapshot who acted; target fields say what was acted on.
type AuditLog struct {
	Base
	ActorAdminID string `gorm:"index" json:"actorAdminId"`
	ActorName    string `json:"actorName"`
	Action       string `gorm:"index" json:"action"` // e.g. admin.create, card.freeze
	TargetType   string `json:"targetType"`          // e.g. admin, card
	TargetID     string `json:"targetId"`
	Detail       string `json:"detail"`
	IP           string `json:"ip"`
}

// PoolStatus is a money pool's lifecycle state.
type PoolStatus string

const (
	PoolOpen   PoolStatus = "open"
	PoolClosed PoolStatus = "closed"
)

// MoneyPool is a "Patungan" — collect contributions toward a target, then cash
// out to the owner's main pocket.
type MoneyPool struct {
	Base
	OwnerUserID string     `gorm:"index;not null" json:"ownerUserId"`
	Title       string     `json:"title"`
	Target      int64      `json:"target"`
	Collected   int64      `json:"collected"`
	Status      PoolStatus `json:"status"`
}

// PoolContribution is one payment into a [MoneyPool].
type PoolContribution struct {
	Base
	PoolID string `gorm:"index;not null" json:"poolId"`
	Name   string `json:"name"`
	Amount int64  `json:"amount"`
}

// All returns every model for AutoMigrate.
func All() []any {
	return []any{
		&User{}, &Account{}, &Pocket{}, &Transaction{},
		&Transfer{}, &Bill{}, &Card{}, &Notification{}, &Contact{},
		&MoneyPool{}, &PoolContribution{}, &PocketMember{}, &AdminUser{},
		&AuditLog{},
	}
}
