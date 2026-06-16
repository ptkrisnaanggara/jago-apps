# Product Requirements Document — JAGO

> Status: Draft · Owner: Product · Last updated: 2026-06-14
>
> This PRD defines how to evolve the current single-screen UI mockup (`lib/`)
> into a complete, production-quality JAGO digital-banking app, built with
> current Flutter best practices.

## 1. Summary

JAGO is a mobile-first **digital banking / e-wallet** app (Indonesian market).
Today the repo contains only a static Home screen mockup. This document
specifies the full product scope, the screens and flows to build, and the
engineering standards every contribution must follow.

### Goals
- Ship a complete, navigable app: onboarding → auth → core banking screens.
- Replace the static mockup with a layered, testable architecture.
- Localize for Bahasa Indonesia (primary) and English (secondary).

### Non-goals (v1)
- Real banking-license integrations, KYC vendors, or live payment rails.
  Use a mock/abstracted data layer; real backends are a later phase.
- Web/desktop targets. v1 is Android + iOS only.

## 2. Personas
- **Daily spender** — checks balance, transfers, pays bills, splits costs.
- **Saver / planner** — creates savings "Kantong" (pockets) and payment plans.
- **New user** — needs frictionless onboarding and account setup.

## 3. Feature scope & screens

Each feature is a vertical slice under `lib/features/<feature>/`. Build in
priority order.

### P0 — Foundation
1. **Onboarding** — intro carousel, get-started CTA.
2. **Auth** — sign up, sign in, OTP verification, sign out. Token persisted
   securely; auth state gates the rest of the app.
3. **App shell / navigation** — persistent bottom navigation (Home, Kantong,
   Kontak, Kartu, Profile) implemented as a real navigator, not the current
   floating-action-button hack.

### P1 — Core banking
4. **Home** — balance summary, search, shortcuts, "Plan Ahead" card, recent
   activity. (Rebuild of the existing `HomePage`.)
5. **Kantong (Pockets)** — list/create/edit savings pockets; main pocket +
   sub-pockets; balance per pocket.
6. **Transfer & Pay (Kirim & Bayar)** — pick contact, enter amount, confirm,
   success receipt.
7. **Transactions** — searchable, filterable history with detail view.

### P2 — Engagement
8. **Bills & Payment Plans** — schedule recurring bill reminders/payments.
9. **Kartu (Cards)** — virtual/physical card display and controls.
10. **Profile & Settings** — personal info, security, language toggle, theme.
11. **Notifications** — in-app notification center.

## 4. Acceptance criteria (per feature)
A feature is "done" when:
- All screens render correctly on small (≤360dp) and large phones, light & dark.
- Loading / empty / error states are handled explicitly (no silent failures).
- Strings are localized (no hardcoded user-facing text).
- Widget tests cover the happy path + at least one error/empty state.
- `flutter analyze` is clean and the feature is reachable via navigation.

## 5. Flutter best practices (engineering standard)

These rules apply to all new code and to refactors of existing code.

### Architecture — layered, feature-first
```
lib/
  core/            # cross-cutting: theme, routing, constants, errors, utils
  features/<name>/
    data/          # models, DTOs, repositories, data sources (api/local)
    domain/        # entities, repository interfaces, use cases (optional)
    presentation/  # screens, widgets, state (controllers/notifiers)
  shared/widgets/  # truly reusable widgets (e.g. CustomCard)
  main.dart
```
- **Separate UI from logic.** Widgets render; state objects hold logic and call
  repositories. No business logic or direct data access inside `build()`.
- **Repository pattern** abstracts data sources behind an interface so the UI
  depends on contracts, not implementations (enables mocking + later real APIs).

### State management
- Adopt **one** declarative solution and use it consistently. Recommended:
  `flutter_riverpod` (or `provider`/`bloc` if the team prefers). Do not mix.
- Prefer immutable state; expose `Loading / Data / Error` states explicitly
  (sealed classes / `AsyncValue`) rather than nullable flags.

### Navigation
- Use **`go_router`** for declarative, deep-link-friendly routing with auth
  redirects. Centralize routes in `core/routing/`.

### Theming & design tokens
- Migrate `lib/theme.dart` into a proper **`ThemeData`** (`ColorScheme`,
  `TextTheme`) supporting **light and dark** modes, consumed via
  `Theme.of(context)` instead of global mutable color/style variables.
- Keep design tokens (spacing, radius) as `const` (current `defaultMargin` etc.
  should be `const double`, not mutable).
- Rename the misleading `kGreenColor` token (its value `0xfffdae27` is orange).

### Code quality
- Enable lints: add `flutter_lints` to `dev_dependencies` and an
  `analysis_options.yaml` with `include: package:flutter_lints/flutter.yaml`.
- Prefer `const` constructors/widgets wherever possible (perf + lint).
- Modern SDK: bump the Dart constraint to a current stable (`>=3.x`) and use
  super-parameters (`const Foo({super.key})`).

### Assets & i18n
- Reference assets through generated constants, not raw string paths, to avoid
  typos. Use `flutter_gen` or a hand-maintained `core/assets.dart`.
- Use Flutter's `gen-l10n` (ARB files) for localization; no hardcoded strings.

### Networking & data (when real backends arrive)
- Centralize HTTP in a typed client (`dio`), with interceptors for auth tokens
  and error mapping. Never call the network from widgets.
- Persist tokens with `flutter_secure_storage`; cache non-sensitive data with
  `shared_preferences` or a local DB.

### Testing
- **Rewrite `test/widget_test.dart`** — it is the stale counter template and
  currently fails. Replace with real tests.
- Layers: unit tests for use cases/repositories (with mocks), widget tests for
  screens, and a few integration tests for critical flows (auth, transfer).

## 6. Migration plan (incremental, no big-bang rewrite)
1. Add `flutter_lints` + `analysis_options.yaml`; fix existing warnings.
2. Introduce `core/` theme as `ThemeData` (light/dark); migrate widgets off
   global mutable styles incrementally.
3. Add `go_router` + app shell with real bottom navigation.
4. Move existing Home into `features/home/presentation/`; move `CustomCard` to
   `shared/widgets/`; remove dead code (`TutorialHome`, unused `FoodCard`).
5. Stand up the repository + state-management layer with mock data sources.
6. Build remaining features P0 → P2, each as a vertical slice.
7. Add localization (ARB) and replace hardcoded strings.

## 7. Open questions
- Confirm state-management choice (Riverpod vs Bloc) before P0.
- Backend availability/timeline for replacing mock data sources.
- Brand color palette and final naming for design tokens.
