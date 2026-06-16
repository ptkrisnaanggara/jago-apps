// Command worker consumes domain events from RabbitMQ. It turns
// `transfer.completed` events into in-app notifications.
package main

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"os"
	"os/signal"
	"syscall"

	"github.com/ptkrisnaanggara/jago-apps/backend/internal/config"
	"github.com/ptkrisnaanggara/jago-apps/backend/internal/event"
	"github.com/ptkrisnaanggara/jago-apps/backend/internal/model"
	"github.com/ptkrisnaanggara/jago-apps/backend/internal/platform/broker"
	"github.com/ptkrisnaanggara/jago-apps/backend/internal/platform/db"
	"github.com/ptkrisnaanggara/jago-apps/backend/internal/platform/logging"
)

const queueName = "notifications.transfer-completed"

func main() {
	cfg := config.Load()
	logger := logging.New(cfg.LogLevel, cfg.LogFormat)

	ctx, stop := signal.NotifyContext(context.Background(), syscall.SIGINT, syscall.SIGTERM)
	defer stop()

	gdb, err := db.Open(cfg.DatabaseURL)
	if err != nil {
		logger.Error("postgres connect failed", "error", err)
		os.Exit(1)
	}

	br, err := broker.Open(cfg.RabbitMQURL)
	if err != nil {
		logger.Error("rabbitmq connect failed", "error", err)
		os.Exit(1)
	}
	defer br.Close()

	logger.Info("worker consuming", "routing_key", event.RoutingTransferCompleted, "queue", queueName)

	err = br.Consume(ctx, queueName, event.RoutingTransferCompleted, func(body []byte) error {
		var ev event.TransferCompleted
		if err := json.Unmarshal(body, &ev); err != nil {
			logger.Warn("drop malformed event", "error", err)
			return nil // don't requeue malformed messages
		}
		notif := model.Notification{
			UserID:   ev.UserID,
			Title:    "Transfer berhasil",
			Body:     fmt.Sprintf("Kamu mengirim Rp%d ke %s.", ev.Amount, ev.RecipientName),
			Category: model.NotifTransaction,
		}
		if err := gdb.Create(&notif).Error; err != nil {
			logger.Error("create notification failed", "user_id", ev.UserID, "error", err)
			return err // requeue is disabled in the broker; logs for visibility
		}
		logger.Info("notification created", "user_id", ev.UserID, "reference_id", ev.ReferenceID)
		return nil
	})

	if err != nil && !errors.Is(err, context.Canceled) {
		logger.Error("consume failed", "error", err)
		os.Exit(1)
	}
}
