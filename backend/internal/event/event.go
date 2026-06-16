// Package event defines the domain events exchanged over the broker.
package event

// Routing keys (topics) published to the jago.events exchange.
const (
	RoutingTransferCompleted = "transfer.completed"
)

// TransferCompleted is emitted after a successful transfer; the worker turns it
// into a notification for the user.
type TransferCompleted struct {
	UserID        string `json:"userId"`
	TransferID    string `json:"transferId"`
	ReferenceID   string `json:"referenceId"`
	RecipientName string `json:"recipientName"`
	Amount        int64  `json:"amount"`
}
