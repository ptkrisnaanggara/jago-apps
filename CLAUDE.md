# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

`jago` is a Flutter **digital banking / e-wallet** app (Indonesian market, logo
"Jago"). It is being built out from an original single-screen mockup toward the
scope in [`PRD.md`](PRD.md), following a layered, feature-first BLoC
architecture. Most UI text is in Bahasa Indonesia (e.g. `Cari Kontak & Tagihan`,
`Kantong Utama`, `Kirim & Bayar`, `Transaksi`).

- SDK: Dart `>=3.0.0 <4.0.0`.
- State management: **BLoC** (`flutter_bloc` + `equatable`).
- Navigation: **`go_router`** with a persistent bottom-nav shell.
- Data: **mock repositories** for now (no real backend yet); swap-in behind
  repository interfaces — see "Data layer" below.
- Other deps: `google_fonts` (Poppins), `intl` (Rupiah / date formatting).

> See [`PRD.md`](PRD.md) for full product scope and the Flutter best-practices
> standard. New work should extend this structure, not regress to the old
> single-file mockup.

## Commands

```bash
flutter pub get          # install dependencies (run after editing pubspec.yaml)
flutter run              # run on a connected device / emulator
flutter analyze          # static analysis / lint (flutter_lints + analysis_options.yaml)
flutter test             # run all tests
flutter test test/features/home/home_bloc_test.dart   # run a single test file
flutter build apk        # Android release build
flutter build ios        # iOS release build
```

## Architecture

Layered, **feature-first**. Each feature is a vertical slice:

```
lib/
  main.dart                     # JagoApp: MultiRepositoryProvider (mocks) + MaterialApp.router
  core/
    theme/        app_colors.dart (Jago palette), app_theme.dart (ThemeData)
    routing/      app_router.dart (go_router), app_shell.dart (bottom nav)
    constants/    app_assets.dart (typed asset paths)
    utils/        currency_formatter.dart (Rupiah via intl)
  features/<name>/
    data/         models/ (Equatable), repositories/ (abstract + Mock impl)
    presentation/ bloc/ (event/state/bloc), pages/, widgets/
  shared/widgets/ # cross-feature widgets (e.g. shortcut_card.dart)
```

Features today: `onboarding`, `auth`, `home`, `kantong`, `transfer`,
`bills`, `transactions`, `profile`.

### Bills & Payment Plans
- `features/bills`: upcoming/overdue + paid bills with quick "Bayar", plus a
  "Rencana Baru" form to schedule a (recurring) bill. Reachable from the Home
  "Plan Ahead" card.
- Like Transfer, the list + create routes (`/bills`, `/bills/new`) sit **outside
  the bottom-nav shell** under a `ShellRoute` that provides one `BillsBloc`, so a
  scheduled bill shows up when you pop back to the list.
- The mock `BillsRepository` keeps a **mutable in-memory list** so pay/schedule
  mutations persist for the session (the only stateful mock so far).

### Transfer & Pay (Kirim & Bayar)
- Multi-step flow (`features/transfer`): pick contact → enter amount + note →
  confirm (bottom sheet) → success receipt. Reachable from Home (the
  "Kirim & Bayar" shortcut and the search bar).
- Steps are **full-screen routes outside the bottom-nav shell**, wrapped in a
  `ShellRoute` whose builder provides a single `TransferBloc` so the selected
  contact/amount survive navigation between steps. The receipt's "Selesai"
  `context.go`s back to `/home`.

### Auth & navigation gating
- `AuthBloc` (in `features/auth`) is created once in `main.dart` (a `StatefulWidget`)
  and provided **above** `MaterialApp.router` so the router can read it.
- `AppRouter.build(authBloc)` wires `redirect` + `refreshListenable`
  (`GoRouterRefreshStream` over the bloc's stream). Redirect rules: `unknown` →
  splash; unauthenticated → onboarding/auth flow; authenticated → app shell
  (and out of the auth flow). Auth-flow routes live **outside** the shell.
- Auth flow is phone + OTP (mock accepts demo code `123456`): onboarding →
  sign in / sign up → OTP → authenticated. Pages dispatch events and use
  `BlocListener` to push the OTP page; reaching `authenticated` lets the router
  redirect Home automatically.

### Data layer (mock-backed)
- Each repository is an **abstract interface** with a `Mock…Repository`
  implementation returning hardcoded data after a simulated `Future.delayed`
  latency. UI/BLoC depend on the interface, never the implementation.
- Mocks are wired once in `main.dart` via `RepositoryProvider`. To add a real
  backend, write a new implementation of the same interface and swap it there —
  no UI changes needed.

### BLoC conventions
- One bloc per feature, split across `*_bloc.dart` / `*_event.dart` /
  `*_state.dart` using `part`/`part of`.
- Events are a **sealed class** hierarchy; the load event is `…Started`.
- State is a single immutable class with a `status` enum
  (`initial / loading / success / failure`) + a `copyWith`. Always handle all
  four states in the UI (loading spinner, error+retry, empty, success).
- Blocs are created in the page via `BlocProvider`, reading repositories from
  `context.read<T>()`; the bloc adds its `…Started` event on creation.

### Theming & design tokens
- `core/theme/app_colors.dart` holds the **Jago brand palette**: `primary` is
  Jago orange (`0xFFFF6B00`); `pocketAccents` is the multi-color list cycled for
  Kantong tiles via `AppColors.pocketAccent(index)`.
- `core/theme/app_theme.dart` exposes a single `ThemeData` (`AppTheme.light`)
  built from a Poppins `TextTheme` + seeded `ColorScheme`. Consume styles via
  `Theme.of(context)` — **do not** reintroduce global mutable color/style
  variables. Layout constants live as `AppTheme.defaultMargin` / `defaultRadius`.

### Conventions
- Imports use the package form `package:jago/...` for cross-feature references;
  relative imports within a feature are fine.
- `assets/` is registered wholesale in `pubspec.yaml`, but reference assets via
  `AppAssets` constants, not raw strings. Re-run `flutter pub get` / hot-restart
  after adding a new asset file.
- Indonesian number/date formatting requires locale data: `main()` calls
  `initializeDateFormatting('id_ID')` before `runApp`. Tests that format dates
  must do the same in `setUpAll`.

## Testing

- Tests live under `test/features/<name>/` mirroring `lib/`.
- Bloc behaviour is tested with `bloc_test` against the mock repositories (see
  `test/features/home/home_bloc_test.dart`). Because mocks use a ~600ms delay,
  `blocTest` needs a `wait:` longer than that.
