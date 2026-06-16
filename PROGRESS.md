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

### Integration
- ✅ Mobile app → backend: Dio API client + token store + API-backed
  repositories for all 8 interfaces, behind `AppConfig.useMockData`

### Repo
- ✅ Monorepo restructure: `backend/`, `mobile-app/`, `frontend/` (history preserved)

---

## In progress

- _(nothing actively in progress — see "This session" for the latest landing)_

---

## Backlog

### Integration
- ⏳ Backend endpoints the app needs but lacks: **contacts** (transfer picker)
  and **home shortcuts** (currently kept static client-side).
- ⏳ Map backend `{error.code}` → app `AppFailure` for precise messages.

### Backend hardening
- 🚫 **End-to-end smoke test** (`docker compose up` + curl flows) — blocked:
  no Docker daemon in this environment. Run locally to verify.
- ⏳ Integration tests (handlers) against test-containerized services
- ⏳ OTP rate-limiting (Redis), request pagination, real SMS delivery
- ⏳ Migrations tool (beyond `AutoMigrate`), structured logging/metrics

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
- Runtime verification against the live API is **blocked** here (no Docker
  daemon to run Postgres/Redis/RabbitMQ); run the backend locally then launch
  the app with `--dart-define=USE_MOCK_DATA=false`.
