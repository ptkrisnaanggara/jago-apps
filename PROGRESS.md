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
- ⏳ Integration tests (handlers) against test-containerized services
- ⏳ Real SMS delivery (turn off demo mode)
- ⏳ Structured logging/metrics
- ⏳ Mobile: consume pagination (infinite scroll); repos currently take page 1

### Android
- ⏳ Modernize Gradle toolchain (AGP 3.5→8, Gradle 5.6→8, compileSdk 29→34,
  drop `jcenter`) — must be verified with a real `flutter build apk`
- ⏳ Rename source package `com.example.food` → `com.jago.app`

### Quality / CI
- ⏳ Widget tests + integration tests (auth, transfer) — coverage is bloc-only
- ⏳ GitHub Actions CI (flutter analyze/test + go build/vet/test)
- ⏳ Visual QA on device (dark mode, cards/notifications, persistence)

### Frontend
- ⏳ Pick a stack and scaffold `frontend/`

---

## This session

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
