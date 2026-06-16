import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/pages/otp_page.dart';
import '../../features/auth/presentation/pages/sign_in_page.dart';
import '../../features/auth/presentation/pages/sign_up_page.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/bills/data/repositories/bills_repository.dart';
import '../../features/bills/presentation/bloc/bills_bloc.dart';
import '../../features/bills/presentation/pages/bills_page.dart';
import '../../features/bills/presentation/pages/create_payment_plan_page.dart';
import '../../features/cards/presentation/pages/cards_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/kantong/presentation/pages/kantong_page.dart';
import '../../features/notifications/presentation/pages/notifications_page.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/qris/presentation/pages/qris_page.dart';
import '../../features/topup/presentation/pages/topup_page.dart';
import '../../features/transactions/presentation/pages/transactions_page.dart';
import '../../features/transfer/data/repositories/transfer_repository.dart';
import '../../features/transfer/presentation/bloc/transfer_bloc.dart';
import '../../features/transfer/presentation/pages/transfer_amount_page.dart';
import '../../features/transfer/presentation/pages/transfer_page.dart';
import '../../features/transfer/presentation/pages/transfer_receipt_page.dart';
import 'app_shell.dart';
import 'go_router_refresh_stream.dart';

/// Declarative routing with auth-gated redirects and a persistent bottom-nav
/// shell. Built from the app-level [AuthBloc] so redirects react to auth state.
class AppRouter {
  AppRouter._();

  static const String splash = '/splash';
  static const String onboarding = '/onboarding';
  static const String signIn = '/signin';
  static const String signUp = '/signup';
  static const String otp = '/otp';
  static const String home = '/home';
  static const String kantong = '/kantong';
  static const String transactions = '/transactions';
  static const String cards = '/cards';
  static const String profile = '/profile';
  static const String transfer = '/transfer';
  static const String transferAmount = '/transfer/amount';
  static const String transferReceipt = '/transfer/receipt';
  static const String bills = '/bills';
  static const String billNew = '/bills/new';
  static const String notifications = '/notifications';
  static const String qris = '/qris';
  static const String topup = '/topup';

  static const Set<String> _authFlow = {
    splash,
    onboarding,
    signIn,
    signUp,
    otp,
  };

  static GoRouter build(AuthBloc authBloc) {
    return GoRouter(
      initialLocation: splash,
      refreshListenable: GoRouterRefreshStream(authBloc.stream),
      redirect: (context, state) {
        final status = authBloc.state.status;
        final loc = state.matchedLocation;
        final inAuthFlow = _authFlow.contains(loc);

        // Session restore still in progress: hold on the splash.
        if (status == AuthStatus.unknown) {
          return loc == splash ? null : splash;
        }

        final authed = status == AuthStatus.authenticated;
        if (!authed) {
          if (loc == splash) return onboarding;
          return inAuthFlow ? null : onboarding;
        }

        // Authenticated: keep users out of the auth flow.
        if (inAuthFlow) return home;
        return null;
      },
      routes: [
        GoRoute(path: splash, builder: (_, __) => const SplashPage()),
        GoRoute(path: onboarding, builder: (_, __) => const OnboardingPage()),
        GoRoute(path: signIn, builder: (_, __) => const SignInPage()),
        GoRoute(path: signUp, builder: (_, __) => const SignUpPage()),
        GoRoute(path: otp, builder: (_, __) => const OtpPage()),
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
              GoRoute(path: cards, builder: (_, __) => const CardsPage()),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(path: profile, builder: (_, __) => const ProfilePage()),
            ]),
          ],
        ),
        // Transfer & Pay flow — full-screen over the shell. A single
        // TransferBloc wraps the steps so the selection survives navigation.
        ShellRoute(
          builder: (context, state, child) => BlocProvider(
            create: (ctx) => TransferBloc(
              repository: ctx.read<TransferRepository>(),
            )..add(const TransferStarted()),
            child: child,
          ),
          routes: [
            GoRoute(path: transfer, builder: (_, __) => const TransferPage()),
            GoRoute(
              path: transferAmount,
              builder: (_, __) => const TransferAmountPage(),
            ),
            GoRoute(
              path: transferReceipt,
              builder: (_, __) => const TransferReceiptPage(),
            ),
          ],
        ),
        // Bills & Payment Plans flow — full-screen over the shell, sharing one
        // BillsBloc so the list reflects bills scheduled on the create page.
        ShellRoute(
          builder: (context, state, child) => BlocProvider(
            create: (ctx) => BillsBloc(
              repository: ctx.read<BillsRepository>(),
            )..add(const BillsStarted()),
            child: child,
          ),
          routes: [
            GoRoute(path: bills, builder: (_, __) => const BillsPage()),
            GoRoute(
              path: billNew,
              builder: (_, __) => const CreatePaymentPlanPage(),
            ),
          ],
        ),
        // Notification center — full-screen over the shell; reads the app-level
        // NotificationsBloc (provided in main.dart).
        GoRoute(
          path: notifications,
          builder: (_, __) => const NotificationsPage(),
        ),
        // QRIS scan-to-pay — full-screen over the shell.
        GoRoute(path: qris, builder: (_, __) => const QrisPage()),
        // Prepaid top-up (pulsa/data) — full-screen over the shell.
        GoRoute(path: topup, builder: (_, __) => const TopupPage()),
      ],
    );
  }
}
