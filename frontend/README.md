# JAGO Admin Dashboard (Web)

A read-only **operator dashboard** for JAGO, built with **Vite + React +
TypeScript**. It consumes the [`backend`](../backend) admin API and gives an
operator a cross-user view: headline stats, a users table (with balances), and
recent transactions across all users.

> The customer-facing product is the Flutter [`mobile-app`](../mobile-app). This
> web app is the **internal admin** surface only.

## Stack

- [Vite](https://vite.dev/) 5 + [React](https://react.dev/) 18 + TypeScript 5
- No UI framework — hand-rolled CSS in `src/index.css` using the Jago palette
  (`--primary: #ff6b00`), mirroring the mobile app's brand.
- `fetch` against the backend; no extra HTTP/state libraries.

## Run

```bash
npm install
npm run dev      # dev server on http://localhost:5173 (proxies /api → :8080)
npm run build    # type-check (tsc -b) + production build to dist/
npm run preview  # serve the production build
```

## Authentication

The admin endpoints are guarded by a static key, **not** a user JWT. On the
login screen, enter:

- **Base URL** — the backend origin, e.g. `http://localhost:8080` (the client
  appends `/api/v1` if you omit it).
- **Admin Key** — the backend's `ADMIN_API_KEY` (default `admin-secret`), sent
  as the `X-Admin-Key` header.

Credentials are verified against `/admin/stats` and then persisted in
`localStorage`; "Keluar" clears them.

## Structure

```
src/
  api.ts                 # typed client + credential storage (X-Admin-Key)
  format.ts              # Rupiah / date formatting (id-ID)
  App.tsx                # login gate → dashboard
  components/
    Login.tsx            # base URL + admin key, verified on submit
    Dashboard.tsx        # stat cards + tab switcher
    UsersTable.tsx       # paginated users (+ account balance)
    TransactionsTable.tsx# paginated cross-user transactions
    Pager.tsx            # prev/next from the backend `meta` block
```

## Backend endpoints used

See [`backend/README.md`](../backend/README.md) → **Admin**:
`GET /api/v1/admin/{stats,users,transactions}` (the list endpoints accept
`?page=&limit=`).
