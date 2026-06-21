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

**Rate limiting** (Redis-backed): OTP requests are capped per phone
(`OTP_MAX_REQUESTS` per `OTP_RATE_WINDOW`, default 5 / 15m) — exceeding it
returns `429` with a `Retry-After` header. Verify attempts are capped per issued
OTP (`OTP_MAX_VERIFY_ATTEMPTS`, default 5); too many wrong guesses returns `429`
and invalidates the code (a new one must be requested).

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

List endpoints (transactions, transfers, bills, notifications, contacts) accept
`?page=` and `?limit=` (default `limit=20`, max `100`) and add a `meta` block
alongside `data`:

```json
{ "data": [ ... ], "meta": { "page": 1, "limit": 20, "total": 42, "totalPages": 3 } }
```

| Method | Path | Description |
| --- | --- | --- |
| `POST` | `/api/v1/auth/otp/request` | Send an OTP for a phone number. |
| `POST` | `/api/v1/auth/otp/verify` | Verify OTP, create/seed user, return JWT. |
| `GET` | `/api/v1/me` | Current user. |
| _(login)_ | `/api/v1/auth/otp/verify` | A user whose `status` is `blocked` is rejected with `403`. |
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

### Admin login (phone + OTP)

Admins live in the **`admin_users`** table (`name`, `phone` unique, `status`
active/disabled, `role`). On boot, if the table is empty, a default admin is
seeded from `ADMIN_SEED_NAME` / `ADMIN_SEED_PHONE` (defaults `Super Admin` /
`81200000000`). Login is phone + OTP; the code is delivered to the admin's
WhatsApp via **WAHA** ([WhatsApp HTTP API](https://waha.devlike.pro)).

| Method | Path | Description |
| --- | --- | --- |
| `POST` | `/api/v1/admin/auth/otp/request` | `{phone}` → look up active admin, store an OTP, send it via WAHA. In demo mode returns `demoCode`. |
| `POST` | `/api/v1/admin/auth/otp/verify` | `{phone,code}` → returns `{token, admin}` (a bearer JWT). |

In demo mode (`OTP_DEMO_MODE=true`) the code is `OTP_DEMO_CODE` (`123456`) and
WhatsApp delivery is best-effort. With `WAHA_BASE_URL` unset, no message is sent
(the demo code still works). Configure WAHA with `WAHA_BASE_URL`, `WAHA_SESSION`
(default `default`) and optional `WAHA_API_KEY`.

### Admin (web dashboard)

These power the [`frontend/`](../frontend) admin dashboard. Each requires **either**
a bearer admin token (from the OTP login) **or** an `X-Admin-Key` header matching
`ADMIN_API_KEY` (default `admin-secret`, handy for curl/tooling).

| Method | Path | Description |
| --- | --- | --- |
| `GET` | `/api/v1/admin/me` | The signed-in admin's profile. |
| `GET` | `/api/v1/admin/stats` | Aggregate counts + total account/pocket balances. |
| `GET` | `/api/v1/admin/stats/charts` | Daily income/expense series (`?days=`, 1–90) + top expense categories. |
| `GET` | `/api/v1/admin/users` | Users with their account balance (paginated). |
| `GET` | `/api/v1/admin/users/:id` | One user's full detail (account, pockets, cards, bills, pools, recent transactions). |
| `PATCH` | `/api/v1/admin/users/:id` | Edit a user's name/phone/`kycStatus`/`status` (partial; 409 on duplicate phone). |
| `GET` | `/api/v1/admin/transactions` | Transactions across all users (paginated; `?type=income\|expense`, `?userId=`). |
| `GET` | `/api/v1/admin/pools` | Money pools across all users with owner name (paginated). |
| `GET` | `/api/v1/admin/audit-logs` | Privileged admin actions (paginated; `?action=`). |
| `POST` | `/api/v1/admin/cards/:id/freeze` | Freeze/unfreeze any card (`{"frozen":true}`). |

Mutating admin actions — **admin login**, user edit, card freeze, and admin
create/edit/status — are recorded in the **`audit_logs`** table (actor, action,
target, detail, IP) and surfaced via `/admin/audit-logs` (filter with `?action=`).

CSV exports (attachment downloads, up to 50k rows):

| Method | Path | Description |
| --- | --- | --- |
| `GET` | `/api/v1/admin/export/users` | Users + balances as CSV. |
| `GET` | `/api/v1/admin/export/transactions` | All transactions as CSV. |
| `GET` | `/api/v1/admin/export/audit-logs` | Audit log as CSV. |

Admin management (**superadmin only**; the static service key also qualifies):

| Method | Path | Description |
| --- | --- | --- |
| `GET` | `/api/v1/admin/admins` | List admins (paginated). |
| `POST` | `/api/v1/admin/admins` | Create an admin (`{name, phone, role}`; 409 on duplicate phone). |
| `PATCH` | `/api/v1/admin/admins/:id` | Edit name/phone/role (partial; 409 on duplicate phone; cannot demote your own role). |
| `POST` | `/api/v1/admin/admins/:id/status` | Enable/disable (`{"status":"active\|disabled"}`; cannot disable yourself). |

The dashboard is a browser client, so the API sends **CORS** headers (the mobile
app, being native, needs none). Allowed origins come from `CORS_ALLOWED_ORIGINS`
(comma-separated, default `*`); auth is header-based (not cookies) so a wildcard
is safe. Preflight `OPTIONS` requests are answered with `204`.

## Logging

Structured logging via the standard library [`log/slog`](https://pkg.go.dev/log/slog)
(no extra deps). Every request emits one JSON line with a correlation id:

```json
{"time":"...","level":"INFO","msg":"http_request","request_id":"…","method":"GET","path":"/api/v1/account","status":200,"latency_ms":2,"ip":"127.0.0.1"}
```

- A request id is generated (or taken from an inbound `X-Request-Id`) and
  returned in the `X-Request-Id` response header.
- Request log level follows status: `INFO` (<400), `WARN` (4xx), `ERROR` (5xx);
  panics are recovered and logged.
- Configure with `LOG_LEVEL` (debug/info/warn/error) and `LOG_FORMAT` (json/text).

## Migrations

Schema is managed with **versioned migrations** ([goose](https://github.com/pressly/goose))
— the TypeORM/Nest equivalent of `migration:run` / `migration:revert`. GORM's
`AutoMigrate` is intentionally not used; the SQL files in `migrations/` are the
source of truth, embedded into the binary and tracked in a `goose_db_version`
table. The API applies pending migrations on boot when `MIGRATE_ON_START=true`
(default; like Nest's `migrationsRun: true`).

| Command (local) | Docker | TypeORM analog |
| --- | --- | --- |
| `go run ./cmd/migrate up` | `docker compose run --rm migrate up` | `migration:run` |
| `go run ./cmd/migrate down` | `… migrate down` | `migration:revert` |
| `go run ./cmd/migrate status` | `… migrate status` | `migration:show` |
| `go run ./cmd/migrate version` | `… migrate version` | — |
| `go run ./cmd/migrate create <name> sql` | — | `migration:create` |

```bash
# write a new migration (edit the -- +goose Up / Down blocks it scaffolds)
go run ./cmd/migrate create add_widgets_table sql
```

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
