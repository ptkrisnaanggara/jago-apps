import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/home/data/repositories/account_repository.dart';
import 'features/kantong/data/repositories/pocket_repository.dart';
import 'features/transactions/data/repositories/transaction_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Required for Indonesian number/date formatting (NumberFormat, DateFormat).
  await initializeDateFormatting('id_ID');
  runApp(const JagoApp());
}

class JagoApp extends StatelessWidget {
  const JagoApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock repositories are wired here. Swap these for real, API-backed
    // implementations without touching the UI (see PRD §5).
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AccountRepository>(
          create: (_) => MockAccountRepository(),
        ),
        RepositoryProvider<TransactionRepository>(
          create: (_) => MockTransactionRepository(),
        ),
        RepositoryProvider<PocketRepository>(
          create: (_) => MockPocketRepository(),
        ),
      ],
      child: MaterialApp.router(
        title: 'JAGO',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        routerConfig: AppRouter.router,
        supportedLocales: const [Locale('id'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
      ),
    );
  }
}
