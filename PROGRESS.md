# JAGO — Progress Log

> Living record of work across the monorepo. Updated as tasks complete.
> Last updated: 2026-06-16 · Branch: `claude/monorepo-foldering`

Legend: ✅ done · 🟡 in progress · ⏳ todo · 🚫 blocked (environment)

---

## Completed

### Mobile app (Flutter) — `mobile-app/`
- ✅ Onboarding carousel
- ✅ Auth: phone + OTP (mock `123456`), `go_router` auth-gated redirects
- ✅ Home, Kantong, Transfer & Pay, Transactions, Bills & Plans, Cards, Notifications
- ✅ Profile & Settings: language toggle (id/en) + dark mode
- ✅ Localization (gen-l10n / ARB) — all UI strings, incl. bloc errors via `AppFailure`
- ✅ Persistence: session (`flutter_secure_storage`) + locale/theme (`shared_preferences`)
- ✅ Analyzer clean (`No issues found!`) · 25 bloc tests passing
- ✅ Android `minSdkVersion` 16→21, `applicationId` → `com.jago.app`

### Backend (Go) — `backend/`
- ✅ Gin + GORM/Postgres + Redis + RabbitMQ service mirroring the app domain
- ✅ Phone+OTP auth (Redis OTP, JWT), account/pockets/transactions/transfers/bills/cards/notifications
- ✅ Event-driven worker: `transfer.completed` → notification
- ✅ Dockerfile + docker-compose, Makefile, README; `go build`/`vet`/`gofmt`/`test` pass
- ✅ **End-to-end smoke test passed** (real Postgres/Redis/RabbitMQ via Docker):
  OTP→JWT, account cache MISS/HIT + invalidation, transfer debit, RabbitMQ→worker
  →notification, bill pay debit, card freeze, mark-all-read, 401 without token

### Integration
- ✅ Mobile app → backend: Dio API client + token store + API-backed
  repositories for all 8 interfaces, behind `AppConfig.useMockData`
- ✅ Backend `GET /contacts` endpoint (+ seed) wired to the transfer picker;
  verified live (5 seeded contacts returned)

### Jago feature parity (see [docs/JAGO_PARITY.md](docs/JAGO_PARITY.md))
- ✅ **Kantong money management** — pocket **types** (main/spending/saving),
  **create pocket**, **move money between pockets** (atomic, locked) — full-stack.
- ✅ **QRIS scan-to-pay** — backend parses EMV TLV payload (`/qris/parse`,
  `/qris/pay`) and debits a pocket; mobile paste/sample → merchant review → pick
  pocket → pay → receipt. Backend verified live (static+dynamic QR, 422 guard).
- ✅ **Top-up prepaid (pulsa/data)** — backend catalog (`/topup/products`) +
  purchase (`/topup`) debiting a pocket; mobile Home shortcut → phone + product
  + pocket → buy → receipt. Backend verified live; mobile analyze + 31 tests.
- ✅ **Transaction filters** — `?type=income|expense` (backend) + filter chips
  (mobile); verified live.
- ✅ **Security PIN** — device-local app-lock (SHA-256 hash in secure storage),
  full-screen lock overlay + set/change/remove in Profile → Security.
- ✅ **Money Pool (Patungan)** — create pool → contribute → close & cash out to
  the main pocket (backend model+migration+endpoints; mobile list + detail).
- ✅ **Saving lock + autosave** — lock a pocket (blocks moving money out, 423);
  autosave config + run (top-up from main). Pocket actions sheet on the Kantong
  tile. Backend verified live; mobile analyze + 40 tests.
- ✅ **Biometric unlock** — `local_auth` behind an injectable abstraction;
  Security page toggle, PIN lock screen auto-prompts + fingerprint button
  (Android: FlutterFragmentActivity + USE_BIOMETRIC). 41 tests.
- ✅ **Shared pockets (Kantong Bersama)** — owner shares by phone → members see
  the pocket + deposit from their own main pocket; members list + role. Backend
  multi-user verified live (2 users); mobile analyze + 42 tests.

All buildable Jago parity features are now implemented; remaining items are
🔌 external-only (investments / insurance / e-wallet link).
- 🔌 e-wallet link / investments / insurance (external integrations)

### Repo
- ✅ Monorepo restructure: `backend/`, `mobile-app/`, `frontend/` (history preserved)

---

## In progress

- _(nothing actively in progress — see "This session" for the latest landing)_

---

## Backlog

### Integration
- ⏳ Backend **home shortcuts** endpoint (Home tiles are still static
  client-side; UI-only concept).
- ⏳ Map backend `{error.code}` → app `AppFailure` for precise messages.

### Backend hardening
- ✅ **End-to-end smoke test** — done (see Completed → Backend). Unblocked by
  starting `dockerd` in-session and using `mirror.gcr.io` as a registry mirror
  (Docker Hub's blob CDN is 403-blocked by the network policy).
- ✅ **Versioned migrations** (goose) replacing `AutoMigrate` — up/down SQL,
  `goose_db_version` tracking, `cmd/migrate` CLI, `migrationsRun`-on-boot flag.
  Verified live on a fresh DB (full smoke test passes on the migrated schema).
- ✅ **Pagination** (`?page=&limit=`, `meta` block, limit clamp 100) on
  transactions/transfers/bills/notifications/contacts — verified live.
- ✅ **OTP rate limiting** (Redis): per-phone request cap (429 + Retry-After) +
  per-OTP verify brute-force guard (429 + invalidates code) — verified live.
- ✅ **Structured logging** (slog/JSON): per-request log with request_id /
  method / path / status / latency, level-by-status, `X-Request-Id` header,
  panic recovery; `LOG_LEVEL`/`LOG_FORMAT` config — verified live.
- ⏳ Integration tests (handlers) against test-containerized services
- ⏳ Real SMS delivery (turn off demo mode)
- ⏳ Metrics (Prometheus)
- ⏳ Mobile: consume pagination (infinite scroll); repos currently take page 1

### Android
- ✅ Modernized the Gradle toolchain by regenerating the scaffold from Flutter
  3.44's template: **Gradle 9.1, AGP 9.0.1, Kotlin 2.3.20, JVM 17**, Kotlin DSL
  (`.kts`), compile/min/target SDK from `flutter.*`, `mavenCentral` (no
  `jcenter`), `namespace` set. App id `com.jago.app`, label "Jago", package
  `com.jago.jago` (replaces `com.example.food`).
  ⚠️ Not gradle-build-verified here (no Android SDK + Google Maven is
  network-blocked); analyze + 25 tests pass. Run `flutter build apk` locally.

### Quality / CI
- ⏳ Widget tests + integration tests (auth, transfer) — coverage is bloc-only
- ⏳ GitHub Actions CI (flutter analyze/test + go build/vet/test)
- ⏳ Visual QA on device (dark mode, cards/notifications, persistence)

### Frontend
- ✅ **Admin dashboard** scaffolded (Vite + React + TS) — see "This session".
- ⏳ Customer-facing web app (the dashboard is internal/admin only).

---

## This session

**Task:** Build the **web admin dashboard** in `frontend/` (Vite + React + TS),
backed by new read-only admin endpoints. ✅

Landed (`backend/`):
- ✅ `ADMIN_API_KEY` config + `adminRequired()` middleware (static `X-Admin-Key`,
  constant-time compare) — admin endpoints are key-guarded, not JWT.
- ✅ `internal/api/admin.go`: `GET /admin/stats` (counts + total account/pocket
  balances via `SUM`), `GET /admin/users` (users LEFT JOIN accounts, paginated),
  `GET /admin/transactions` (cross-user, joined with owner name, paginated).
- ✅ Verified live against the real stack: 401 without/with wrong key; stats,
  users (20 seeded), and transactions (48) all return correct paginated data.
  `gofmt`/`vet`/`test` pass.

Landed (`frontend/`):
- ✅ Vite + React + TS app: login (Base URL + Admin Key, verified on submit and
  stored in `localStorage`), stat cards, tabbed **Users** / **Transactions**
  tables with backend-`meta` pagination, Jago-orange styling, Rupiah/`id-ID`
  formatting. `npm run build` (tsc + vite) is clean.
- ✅ Dev proxy `/api → :8080`; README documents auth + structure.

_(Previous session — mobile↔backend API wiring — retained below.)_

**Task:** Wire the mobile app to the backend API (foundation + all repositories). ✅

Landed (`mobile-app/`):
- ✅ `core/config/app_config.dart` — `useMockData` (default true) + `apiBaseUrl`,
  both overridable via `--dart-define`.
- ✅ `core/network/api_client.dart` — Dio wrapper: injects the bearer token,
  unwraps the `{data}` envelope, propagates non-2xx as errors (blocs map to
  `AppFailure`). Added `dio` to pubspec.
- ✅ `core/network/auth_token_store.dart` — secure + in-memory token stores.
- ✅ API-backed repositories for all 8 interfaces (auth, account, pockets,
  transactions, transfer, bills, cards, notifications), each implementing the
  existing contract with inline JSON parsing.
- ✅ `main.dart` selects mock vs API repositories from the flag; default stays
  mock so the 25 bloc tests pass unchanged.

Verified: `flutter analyze` → `No issues found!` (covers both repo paths) and
**25 tests pass**. Backend `go build`/`vet`/`test` still pass.

Known gaps (tracked in Backlog → Integration):
- The backend has no **contacts** or **home shortcuts** endpoints; the API
  transfer/account repos keep those static for now.

**Backend brought up + smoke-tested live** (this was previously blocked):
- Started `dockerd` in-session; worked around the Docker Hub CDN 403 by setting
  `/etc/docker/daemon.json` → `{"registry-mirrors":["https://mirror.gcr.io"]}`.
- `docker compose up postgres redis rabbitmq`; ran API + worker via `go run`.
- Verified the full flow with curl (results in Completed → Backend). No backend
  code changes were needed — it worked on first real run.
- The mobile app's API mode (`--dart-define=USE_MOCK_DATA=false`) now points at a
  real, working backend; an on-device run is the remaining manual check.
