# JAGO Admin Dashboard (Web)

An **operator dashboard** for JAGO, built with **Vite + React + TypeScript**. It
consumes the [`backend`](../backend) admin API and gives an operator a cross-user
view: headline stats; URL-routed tabs for users, transactions (with type
filters) and money pools; and a **full-page** per-user detail (account, pockets,
cards, bills, pools, recent transactions) reached by clicking a row. The one
write action is freezing/unfreezing a user's card from the detail page.

> The customer-facing product is the Flutter [`mobile-app`](../mobile-app). This
> web app is the **internal admin** surface only.

## Stack

- [Vite](https://vite.dev/) 5 + [React](https://react.dev/) 18 + TypeScript 5
  (strict), `@/*` path alias → `src/`.
- [React Router](https://reactrouter.com/) 6 for client-side routing
  (`BrowserRouter`); auth credentials shared via a small React context.
- No UI framework — hand-rolled CSS in `src/index.css` using the Jago palette
  (`--primary: #ff6b00`), mirroring the mobile app's brand.
- `fetch` against the backend; no extra HTTP/state libraries.
- Tooling: **ESLint** (flat config) + **Prettier**, **Vitest** +
  **Testing Library** (jsdom), split `tsconfig` (app/node), `ErrorBoundary`.

## Scripts

```bash
npm install
npm run dev          # dev server on http://localhost:5173 (proxies /api → :8080)
npm run build        # type-check (tsc -b) + production build to dist/
npm run preview      # serve the production build
npm run lint         # ESLint
npm run format       # Prettier (write); format:check to verify
npm run typecheck    # tsc --noEmit
npm test             # Vitest (run once); test:watch to watch
```

## Configuration

Client config is via `VITE_*` env vars (see [`.env.example`](.env.example)):

- `VITE_API_BASE_URL` — default backend origin pre-filled on the login form
  (defaults to `http://localhost:8080`; the client appends `/api/v1`).
- `VITE_DEMO_OTP` — accepted OTP code for the demo login (defaults to `123456`).

## Authentication

The admin endpoints are guarded by a static key, **not** a user JWT. Login is a
two-step flow:

1. **Base URL** (the backend origin, e.g. `http://localhost:8080`; the client
   appends `/api/v1`) + **Admin Key** (the backend's `ADMIN_API_KEY`, default
   `admin-secret`, sent as the `X-Admin-Key` header). These are verified against
   `/admin/stats`.
2. **OTP** — a one-time code. The demo code is `123456` (configurable via
   `VITE_DEMO_OTP`), mirroring the mobile app / backend demo code.

On success the credentials are persisted in `localStorage`; "Keluar" clears them.

## Structure

```
src/
  lib/
    api.ts             # typed fetch client (X-Admin-Key); normalizeBase
    config.ts          # env config (VITE_API_BASE_URL, VITE_DEMO_OTP)
    credentials.ts     # Credentials type + localStorage helpers
    types.ts           # domain types mirroring the API responses
    format.ts          # Rupiah / date formatting (id-ID)
  context/
    auth.ts            # AuthContext + useAuth (creds + logout, no prop-drilling)
  hooks/
    usePagedList.ts    # shared paginated-fetch hook (cancels stale responses)
  components/
    Login.tsx          # base URL + admin key, verified on submit
    AppLayout.tsx      # persistent brand topbar + <Outlet/>
    DashboardShell.tsx # stat cards + NavLink tabs + <Outlet/> for list routes
    UsersTable.tsx     # paginated users; rows navigate to /users/:id
    TransactionsTable.tsx # paginated cross-user transactions + type filter
    PoolsTable.tsx     # paginated money pools (+ owner name)
    Pager.tsx          # prev/next from the backend `meta` block
    Logo.tsx           # inline Jago wordmark (brand)
    ErrorBoundary.tsx  # catches render errors → recoverable fallback
  pages/
    UserDetailPage.tsx # full-page /users/:id: pockets/cards/bills/pools/txns + freeze
  App.tsx              # login gate → routed dashboard
  test/setup.ts        # Testing Library / jsdom setup
```

Routes: `/` (users) · `/transactions` · `/pools` · `/users/:id` (detail). All
sit under `AppLayout`; the three list tabs also share `DashboardShell` (stats +
tab nav). Tests live next to the code they cover (`*.test.ts[x]`).

## Backend endpoints used

See [`backend/README.md`](../backend/README.md) → **Admin**:
`GET /api/v1/admin/{stats,users,users/:id,transactions,pools}` and
`POST /api/v1/admin/cards/:id/freeze` (list endpoints accept `?page=&limit=`;
transactions also `?type=` and `?userId=`).
