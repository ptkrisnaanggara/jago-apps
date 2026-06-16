// Package broker wraps RabbitMQ: a single topic exchange used to publish and
// consume domain events.
package broker

import (
	"context"
	"fmt"

	amqp "github.com/rabbitmq/amqp091-go"
)

// ExchangeName is the topic exchange all domain events flow through.
const ExchangeName = "jago.events"

// Broker owns the AMQP connection + channel and declares the exchange.
type Broker struct {
	conn *amqp.Connection
	ch   *amqp.Channel
}

// Open dials RabbitMQ and declares the durable topic exchange.
func Open(url string) (*Broker, error) {
	conn, err := amqp.Dial(url)
	if err != nil {
		return nil, fmt.Errorf("dial rabbitmq: %w", err)
	}
	ch, err := conn.Channel()
	if err != nil {
		_ = conn.Close()
		return nil, fmt.Errorf("open channel: %w", err)
	}
	if err := ch.ExchangeDeclare(ExchangeName, "topic", true, false, false, false, nil); err != nil {
		_ = conn.Close()
		return nil, fmt.Errorf("declare exchange: %w", err)
	}
	return &Broker{conn: conn, ch: ch}, nil
}

// Publish sends a JSON-encoded body to the exchange under routingKey.
func (b *Broker) Publish(ctx context.Context, routingKey string, body []byte) error {
	return b.ch.PublishWithContext(ctx, ExchangeName, routingKey, false, false, amqp.Publishing{
		ContentType:  "application/json",
		Body:         body,
		DeliveryMode: amqp.Persistent,
	})
}

// Consume binds a durable queue to routingKey and invokes handler per message.
// It blocks until ctx is cancelled. A handler returning nil acks the message;
// a non-nil error nacks it (no requeue, to avoid poison-message loops).
func (b *Broker) Consume(ctx context.Context, queue, routingKey string, handler func([]byte) error) error {
	q, err := b.ch.QueueDeclare(queue, true, false, false, false, nil)
	if err != nil {
		return fmt.Errorf("declare queue: %w", err)
	}
	if err := b.ch.QueueBind(q.Name, routingKey, ExchangeName, false, nil); err != nil {
		return fmt.Errorf("bind queue: %w", err)
	}
	deliveries, err := b.ch.Consume(q.Name, "", false, false, false, false, nil)
	if err != nil {
		return fmt.Errorf("consume: %w", err)
	}
	for {
		select {
		case <-ctx.Done():
			return ctx.Err()
		case d, ok := <-deliveries:
			if !ok {
				return fmt.Errorf("delivery channel closed")
			}
			if err := handler(d.Body); err != nil {
				_ = d.Nack(false, false)
				continue
			}
			_ = d.Ack(false)
		}
	}
}

// Close tears down the channel and connection.
func (b *Broker) Close() {
	if b.ch != nil {
		_ = b.ch.Close()
	}
	if b.conn != nil {
		_ = b.conn.Close()
	}
}
