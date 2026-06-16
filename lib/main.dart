import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'l10n/app_localizations.dart';
import 'features/auth/data/repositories/auth_repository.dart';
import 'features/auth/data/sources/auth_session_store.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/bills/data/repositories/bills_repository.dart';
import 'features/cards/data/repositories/cards_repository.dart';
import 'features/home/data/repositories/account_repository.dart';
import 'features/kantong/data/repositories/pocket_repository.dart';
import 'features/notifications/data/repositories/notifications_repository.dart';
import 'features/notifications/presentation/bloc/notifications_bloc.dart';
import 'features/settings/data/settings_store.dart';
import 'features/settings/presentation/bloc/settings_bloc.dart';
import 'features/transactions/data/repositories/transaction_repository.dart';
import 'features/transfer/data/repositories/transfer_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Required for Indonesian number/date formatting (NumberFormat, DateFormat).
  await initializeDateFormatting('id_ID');

  // Load persisted preferences before first paint so there's no theme/locale
  // flash on cold start.
  final settingsStore = PrefsSettingsStore(await SharedPreferences.getInstance());
  final saved = await settingsStore.read();
  final initialSettings = SettingsState(
    locale: saved.locale ?? const Locale('id'),
    themeMode: saved.themeMode ?? ThemeMode.system,
  );

  runApp(JagoApp(
    settingsStore: settingsStore,
    initialSettings: initialSettings,
  ));
}

class JagoApp extends StatefulWidget {
  final SettingsStore settingsStore;
  final SettingsState initialSettings;

  const JagoApp({
    super.key,
    required this.settingsStore,
    required this.initialSettings,
  });

  @override
  State<JagoApp> createState() => _JagoAppState();
}

class _JagoAppState extends State<JagoApp> {
  // Mock repositories are wired here. Swap these for real, API-backed
  // implementations without touching the UI (see PRD §5).
  // Session persists in secure storage, so a restored session keeps the user
  // signed in across restarts (AuthStarted reads it on launch).
  final AuthRepository _authRepository =
      MockAuthRepository(session: const SecureAuthSessionStore());
  final NotificationsRepository _notificationsRepository =
      MockNotificationsRepository();

  // AuthBloc and the router are created once and kept stable for the app's
  // lifetime so redirects react to auth changes without rebuilding the router.
  late final AuthBloc _authBloc =
      AuthBloc(repository: _authRepository)..add(const AuthStarted());
  late final SettingsBloc _settingsBloc = SettingsBloc(
    store: widget.settingsStore,
    initialState: widget.initialSettings,
  );
  // App-level so the Home bell badge + notifications page share one state.
  late final NotificationsBloc _notificationsBloc =
      NotificationsBloc(repository: _notificationsRepository)
        ..add(const NotificationsStarted());
  late final GoRouter _router = AppRouter.build(_authBloc);

  @override
  void dispose() {
    _authBloc.close();
    _settingsBloc.close();
    _notificationsBloc.close();
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
        RepositoryProvider<CardsRepository>(
          create: (_) => MockCardsRepository(),
        ),
        RepositoryProvider<NotificationsRepository>.value(
          value: _notificationsRepository,
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>.value(value: _authBloc),
          BlocProvider<SettingsBloc>.value(value: _settingsBloc),
          BlocProvider<NotificationsBloc>.value(value: _notificationsBloc),
        ],
        // Rebuilds locale + theme when the user changes them in Settings.
        child: BlocBuilder<SettingsBloc, SettingsState>(
          builder: (context, settings) {
            return MaterialApp.router(
              onGenerateTitle: (context) =>
                  AppLocalizations.of(context)!.appTitle,
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
              themeMode: settings.themeMode,
              routerConfig: _router,
              // Bahasa Indonesia is the default locale (PRD §1); switchable to
              // English via Profile → Language.
              locale: settings.locale,
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
            );
          },
        ),
      ),
    );
  }
}
