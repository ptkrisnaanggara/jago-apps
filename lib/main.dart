import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'l10n/app_localizations.dart';
import 'features/auth/data/repositories/auth_repository.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/bills/data/repositories/bills_repository.dart';
import 'features/home/data/repositories/account_repository.dart';
import 'features/kantong/data/repositories/pocket_repository.dart';
import 'features/transactions/data/repositories/transaction_repository.dart';
import 'features/transfer/data/repositories/transfer_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Required for Indonesian number/date formatting (NumberFormat, DateFormat).
  await initializeDateFormatting('id_ID');
  runApp(const JagoApp());
}

class JagoApp extends StatefulWidget {
  const JagoApp({super.key});

  @override
  State<JagoApp> createState() => _JagoAppState();
}

class _JagoAppState extends State<JagoApp> {
  // Mock repositories are wired here. Swap these for real, API-backed
  // implementations without touching the UI (see PRD §5).
  final AuthRepository _authRepository = MockAuthRepository();

  // AuthBloc and the router are created once and kept stable for the app's
  // lifetime so redirects react to auth changes without rebuilding the router.
  late final AuthBloc _authBloc =
      AuthBloc(repository: _authRepository)..add(const AuthStarted());
  late final GoRouter _router = AppRouter.build(_authBloc);

  @override
  void dispose() {
    _authBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AuthRepository>.value(value: _authRepository),
        RepositoryProvider<AccountRepository>(
          create: (_) => MockAccountRepository(),
        ),
        RepositoryProvider<TransactionRepository>(
          create: (_) => MockTransactionRepository(),
        ),
        RepositoryProvider<PocketRepository>(
          create: (_) => MockPocketRepository(),
        ),
        RepositoryProvider<TransferRepository>(
          create: (_) => MockTransferRepository(),
        ),
        RepositoryProvider<BillsRepository>(
          create: (_) => MockBillsRepository(),
        ),
      ],
      child: BlocProvider<AuthBloc>.value(
        value: _authBloc,
        child: MaterialApp.router(
          onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          routerConfig: _router,
          // Bahasa Indonesia is the primary locale (PRD §1); English is
          // available for the future language toggle (P2 #10).
          locale: const Locale('id'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
        ),
      ),
    );
  }
}
