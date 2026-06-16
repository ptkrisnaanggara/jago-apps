# JAGO Backend

Go API for the [JAGO](../README.md) digital-banking app, built with **Gin**,
**GORM/PostgreSQL**, **Redis**, and **RabbitMQ**.

## Stack & how each piece is used

| Tech | Role |
| --- | --- |
| **Gin** | HTTP routing, middleware (JWT auth), JSON. |
| **GORM + PostgreSQL** | Persistence; `AutoMigrate` on boot; row-locked balance updates inside transactions. |
| **Redis** | OTP storage (with TTL) and short-lived account-balance cache. |
| **RabbitMQ** | Domain events on a topic exchange (`jago.events`). The API publishes `transfer.completed`; the **worker** consumes it and writes a notification. |
| **JWT** | Stateless auth (`golang-jwt`), subject = user ID. |

## Architecture

```
cmd/
  api/      HTTP server entrypoint
  worker/   RabbitMQ consumer entrypoint
internal/
  config/           env-based configuration
  model/            GORM entities (User, Account, Pocket, Transaction, Transfer, Bill, Card, Notification)
  platform/db/      Postgres + migrations
  platform/cache/   Redis client
  platform/broker/  RabbitMQ exchange / publish / consume
  event/            event topics + payloads
  token/            JWT issue/verify
  api/              Gin server, router, middleware, handlers
```

## Run

### With Docker (everything)

```bash
docker compose up --build       # postgres, redis, rabbitmq, api, worker
```

API on `http://localhost:8080`, RabbitMQ UI on `http://localhost:15672` (guest/guest).

### Locally (Go + your own services)

```bash
cp .env.example .env            # adjust if needed
make run                        # API     (terminal 1)
make worker                     # worker  (terminal 2)
```

## Auth flow (mock OTP)

Demo mode is on by default: the OTP is always `123456` (and echoed back in the
request response for convenience).

```bash
# 1. request an OTP
curl -s localhost:8080/api/v1/auth/otp/request \
  -H 'Content-Type: application/json' -d '{"phone":"81234567890"}'

# 2. verify -> returns a JWT (and creates + seeds the user on first login)
TOKEN=$(curl -s localhost:8080/api/v1/auth/otp/verify \
  -H 'Content-Type: application/json' \
  -d '{"phone":"81234567890","code":"123456","name":"Shankara"}' | jq -r .data.token)

# 3. call a secured endpoint
curl -s localhost:8080/api/v1/account -H "Authorization: Bearer $TOKEN"
```

## API

All responses use `{"data": ...}` on success and
`{"error": {"code","message"}}` on failure. Secured routes require
`Authorization: Bearer <token>`.

| Method | Path | Description |
| --- | --- | --- |
| `POST` | `/api/v1/auth/otp/request` | Send an OTP for a phone number. |
| `POST` | `/api/v1/auth/otp/verify` | Verify OTP, create/seed user, return JWT. |
| `GET` | `/api/v1/me` | Current user. |
| `GET` | `/api/v1/account` | Balance (Redis-cached). |
| `GET` | `/api/v1/pockets` | Savings pockets. |
| `GET` | `/api/v1/transactions` | Transaction history. |
| `GET` | `/api/v1/contacts` | Saved transfer recipients. |
| `GET`/`POST` | `/api/v1/transfers` | List / create a transfer (publishes an event). |
| `GET`/`POST` | `/api/v1/bills` | List / schedule a bill. |
| `POST` | `/api/v1/bills/:id/pay` | Pay a bill. |
| `GET` | `/api/v1/cards` | List cards. |
| `POST` | `/api/v1/cards/:id/freeze` | Freeze/unfreeze a card (`{"frozen":true}`). |
| `GET` | `/api/v1/notifications` | List notifications. |
| `POST` | `/api/v1/notifications/:id/read` | Mark one read. |
| `POST` | `/api/v1/notifications/read-all` | Mark all read. |

## Commands

```bash
make build   # compile
make vet     # go vet
make test    # unit tests
make up      # docker compose up --build -d
make down    # docker compose down
```

## Notes

- This mirrors the Flutter app's domain; amounts are whole Rupiah (`int64`).
- Seeded demo data is created on a user's first login so the app's screens are
  populated immediately.
