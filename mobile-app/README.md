# JAGO — Mobile App (Flutter)

A Flutter **digital banking / e-wallet** app for the Indonesian market, built
out from a single-screen mockup into a layered, feature-first
[BLoC](https://bloclibrary.dev) application. Most UI copy is in Bahasa Indonesia
(e.g. *Kirim & Bayar*, *Kantong Utama*, *Tagihan & Rencana*), with English
available via an in-app language toggle.

> See [`../PRD.md`](../PRD.md) for full product scope and the engineering
> standard, and [`../CLAUDE.md`](../CLAUDE.md) for architecture conventions. The
> API that will back this app lives in [`../backend`](../backend).

## Features

| Area | What's there |
| --- | --- |
| **Onboarding** | Intro carousel into the auth flow. |
| **Auth** | Phone + OTP sign in / sign up (mock demo code `123456`); `go_router` redirects gate the app by auth state. |
| **Home** | Balance card, search, shortcuts, "Plan Ahead" card, recent activity, live notification badge. |
| **Kantong (Pockets)** | Savings pockets with per-pocket balance and goal progress. |
| **Transfer & Pay** | Multi-step flow: pick contact → amount + note → confirm → receipt. |
| **Bills & Plans** | Upcoming/overdue + paid bills, quick pay, and scheduling a recurring bill. |
| **Transactions** | Searchable transaction history. |
| **Cards (Kartu)** | Card visuals with freeze/unfreeze and reveal-details controls. |
| **Notifications** | In-app center with read/unread state and "mark all read". |
| **Profile & Settings** | Language toggle (id/en) and theme (System/Light/Dark). |

## Tech stack

- **Flutter** (Dart `>=3.0.0 <4.0.0`)
- **State management:** `flutter_bloc` + `equatable`
- **Navigation:** `go_router` with a persistent bottom-nav shell + auth redirects
- **Localization:** `gen-l10n` / ARB (`id` primary, `en` secondary)
- **Formatting & fonts:** `intl` (Rupiah / dates), `google_fonts` (Poppins)
- **Persistence:** `flutter_secure_storage` (session) + `shared_preferences` (locale/theme)
- **Data:** mock repositories behind interfaces (swap for the `../backend` API)

## Architecture

Layered and feature-first — each feature is a vertical slice:

```
lib/
  main.dart                     # app-level providers (mock repos + Auth/Settings/Notifications blocs)
  core/                         # theme, routing, constants, errors, utils
  features/<name>/
    data/         models/ + repositories/ (abstract interface + Mock impl)
    presentation/ bloc/ (event/state/bloc) + pages/ + widgets/
  shared/widgets/               # cross-feature widgets
  l10n/                         # app_en.arb (template) + app_id.arb
```

- **Repository pattern:** UI/BLoC depend on interfaces, never the mock
  implementations — swap in a real backend without touching the UI.
- **Errors:** blocs emit `AppFailure` codes (`core/errors`), resolved to
  localized text in the UI via `failureText`.

## Getting started

All commands run from this `mobile-app/` directory.

```bash
flutter pub get          # install dependencies (regenerates l10n)
flutter run              # run on a connected device / emulator
```

> The auth flow is mock-only: enter any phone number and use OTP **`123456`**.

## Commands

```bash
flutter pub get          # install dependencies (run after editing pubspec.yaml)
flutter analyze          # static analysis / lint
flutter test             # run all tests
flutter test test/features/home/home_bloc_test.dart   # run a single test file
flutter gen-l10n         # regenerate localizations from ARB files
flutter build apk        # Android release build
flutter build ios        # iOS release build
```

## Testing

Tests live under `test/features/<name>/` mirroring `lib/`. BLoC behaviour is
tested with `bloc_test` against the mock repositories.

## Status

P0–P2 of the PRD are implemented (onboarding, auth, core banking, engagement
features). The data layer is mock-backed; wiring it to the `../backend` API is
the next milestone.
