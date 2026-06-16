// Command worker consumes domain events from RabbitMQ. It turns
// `transfer.completed` events into in-app notifications.
package main

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"log"
	"os/signal"
	"syscall"

	"github.com/ptkrisnaanggara/jago-apps/backend/internal/config"
	"github.com/ptkrisnaanggara/jago-apps/backend/internal/event"
	"github.com/ptkrisnaanggara/jago-apps/backend/internal/model"
	"github.com/ptkrisnaanggara/jago-apps/backend/internal/platform/broker"
	"github.com/ptkrisnaanggara/jago-apps/backend/internal/platform/db"
)

const queueName = "notifications.transfer-completed"

func main() {
	cfg := config.Load()

	ctx, stop := signal.NotifyContext(context.Background(), syscall.SIGINT, syscall.SIGTERM)
	defer stop()

	gdb, err := db.Open(cfg.DatabaseURL)
	if err != nil {
		log.Fatalf("postgres: %v", err)
	}

	br, err := broker.Open(cfg.RabbitMQURL)
	if err != nil {
		log.Fatalf("rabbitmq: %v", err)
	}
	defer br.Close()

	log.Printf("worker consuming %q on %q", event.RoutingTransferCompleted, queueName)

	err = br.Consume(ctx, queueName, event.RoutingTransferCompleted, func(body []byte) error {
		var ev event.TransferCompleted
		if err := json.Unmarshal(body, &ev); err != nil {
			log.Printf("drop malformed event: %v", err)
			return nil // don't requeue malformed messages
		}
		notif := model.Notification{
			UserID:   ev.UserID,
			Title:    "Transfer berhasil",
			Body:     fmt.Sprintf("Kamu mengirim Rp%d ke %s.", ev.Amount, ev.RecipientName),
			Category: model.NotifTransaction,
		}
		if err := gdb.Create(&notif).Error; err != nil {
			log.Printf("create notification failed: %v", err)
			return err // requeue is disabled in the broker; logs for visibility
		}
		log.Printf("notification created for user %s (ref %s)", ev.UserID, ev.ReferenceID)
		return nil
	})

	if err != nil && !errors.Is(err, context.Canceled) {
		log.Fatalf("consume: %v", err)
	}
}
