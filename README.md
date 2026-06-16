# JAGO

A **digital banking / e-wallet** product for the Indonesian market, organized as
a monorepo. See [`PRD.md`](PRD.md) for product scope and the engineering
standard, and [`CLAUDE.md`](CLAUDE.md) for architecture conventions.

## Repository layout

| Folder | Project | Stack | Status |
| --- | --- | --- | --- |
| [`mobile-app/`](mobile-app) | Flutter mobile app | Flutter, BLoC, go_router, gen-l10n | P0–P2 features implemented (mock data layer) |
| [`backend/`](backend) | API service | Go, Gin, GORM/Postgres, Redis, RabbitMQ | Core domain + event worker; compiles & unit-tested |
| [`frontend/`](frontend) | Web frontend | TBD | Scaffold / not started |

Each project has its own README with setup and commands:

- **Mobile app** → [`mobile-app/README.md`](mobile-app/README.md)
- **Backend** → [`backend/README.md`](backend/README.md)
- **Frontend** → [`frontend/README.md`](frontend/README.md)

## Quick start

```bash
# Backend (Postgres + Redis + RabbitMQ + API + worker)
cd backend && docker compose up --build

# Mobile app
cd mobile-app && flutter pub get && flutter run
```

The mobile app and the web frontend both consume the `backend` API
(`/api/v1/*`, JWT auth, `{data}` / `{error}` envelope). Auth is phone + OTP with
a demo code of **`123456`**.
