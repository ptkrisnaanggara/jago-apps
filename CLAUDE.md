# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

`jago` is a single-screen Flutter mobile app — a UI mockup of an Indonesian
digital-banking / e-wallet home screen (logo "Jago"). It is essentially a static
layout demo: there is no state management, networking, or persistence. Most UI
text is in Indonesian (e.g. `Cari Kontak & Tagihan`, `Kantong Utama`,
`Kirim & Bayar`).

- SDK constraint: Dart `>=2.12.0 <3.0.0` (null-safety enabled).
- Dependencies: only `cupertino_icons` and `google_fonts` (Poppins font).

> **Where the product is headed:** see [`PRD.md`](PRD.md) for the full product
> scope (onboarding, auth, Kantong, Transfer, etc.) and the Flutter
> best-practices / architecture standard to follow when building it out.
> New work should align with the target layered, feature-first structure
> described there rather than extending the current single-file mockup.

## Commands

```bash
flutter pub get          # install dependencies (run after editing pubspec.yaml)
flutter run              # run on a connected device / emulator
flutter analyze          # static analysis / lint
flutter test             # run all tests
flutter test test/widget_test.dart --plain-name "Counter increments smoke test"  # single test
flutter build apk        # Android release build
flutter build ios        # iOS release build
```

## Architecture

The app is intentionally small. Key files in `lib/`:

- `main.dart` — entry point. `main()` runs `MyApp`, whose `home` is `HomePage()`.
  Note: this file also defines a `TutorialHome` widget that is **dead code** —
  it is the leftover Flutter starter scaffold and is not referenced anywhere.
- `theme.dart` — the **design-token system** for the whole app. Defines global
  top-level constants used everywhere: `defaultMargin`/`defaultRadius`, color
  constants (`kBlackColor`, `kGreenColor` — note the green is actually the orange
  `0xfffdae27`, `kLightGreyColor`, etc.), Poppins `TextStyle`s (`blackTextStyle`,
  `greyTextStyle`, `greenTextStyle`, `whiteTextStyle`), and named `FontWeight`
  aliases (`thin` … `black`). Styling convention everywhere: start from a base
  text style and override with `.copyWith(fontWeight: ..., fontSize: ...)`.
- `pages/home/home_page.dart` — the only real screen. `HomePage` is a
  `StatelessWidget` that composes the screen from private `buildXxx()` helper
  methods (`buildAppBar`, `buildSearchBar`, `buildTabBar`, `buildPlanCard`,
  `buildPopularFood`, `buildBottomNav`), assembled in a `ListView` inside
  `build()`. The bottom nav is rendered via `floatingActionButton` +
  `FloatingActionButtonLocation.centerFloat` rather than a real `BottomNavigationBar`.
- `widgets/` — reusable cards. `CustomCard` (name/price/imageUrl) is the one in
  use; a `price` of `-1` is a sentinel meaning "hide the price". `FoodCard` is an
  older variant that is **currently unused** (its import in `home_page.dart` is
  commented out).

### Conventions

- Layout is built almost entirely from `Container` + `BoxDecoration` with
  `DecorationImage(AssetImage(...))`, rather than `Image` widgets or icon fonts.
  Icons/illustrations are PNG assets in `assets/`.
- `assets/` is registered wholesale in `pubspec.yaml` (`- assets/`), so any new
  file dropped in that folder is available without editing pubspec — but you must
  re-run `flutter pub get` / hot-restart for new assets to load.
- New screens go under `lib/pages/<feature>/`; shared widgets under `lib/widgets/`.
- Imports use the package form `package:jago/...`, not relative paths.

## Testing caveat

`test/widget_test.dart` is the **stale default Flutter counter template** and
does not match the actual app — it asserts on a counter (`find.text('0')`, tapping
`Icons.add`) that `MyApp`/`HomePage` does not have, so `flutter test` will fail
until this test is rewritten. Replace it with tests against the real `HomePage`
when adding test coverage.
