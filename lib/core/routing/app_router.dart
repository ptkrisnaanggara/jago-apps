import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/home/presentation/pages/home_page.dart';
import '../../features/kantong/presentation/pages/kantong_page.dart';
import '../../features/transactions/presentation/pages/transactions_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import 'app_shell.dart';

/// Declarative routing with a persistent bottom-nav shell.
/// Each tab is a [StatefulShellBranch] so its navigation state is preserved.
class AppRouter {
  AppRouter._();

  static const String home = '/home';
  static const String kantong = '/kantong';
  static const String transactions = '/transactions';
  static const String profile = '/profile';

  static final GoRouter router = GoRouter(
    initialLocation: home,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: home, builder: (_, __) => const HomePage()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: kantong, builder: (_, __) => const KantongPage()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: transactions,
              builder: (_, __) => const TransactionsPage(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: profile, builder: (_, __) => const ProfilePage()),
          ]),
        ],
      ),
    ],
  );
}
