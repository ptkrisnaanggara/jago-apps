import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:jago/features/notifications/presentation/bloc/notifications_bloc.dart';
import 'package:jago/l10n/app_localizations.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/errors/failure_l10n.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/widgets/shortcut_card.dart';
import '../../../transactions/data/repositories/transaction_repository.dart';
import '../../data/repositories/account_repository.dart';
import '../bloc/home_bloc.dart';
import '../widgets/balance_card.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => HomeBloc(
        accountRepository: context.read<AccountRepository>(),
        transactionRepository: context.read<TransactionRepository>(),
      )..add(const HomeStarted()),
      child: const _HomeView(),
    );
  }
}

class _HomeView extends StatelessWidget {
  const _HomeView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<HomeBloc, HomeState>(
          builder: (context, state) {
            switch (state.status) {
              case HomeStatus.initial:
              case HomeStatus.loading:
                return const Center(child: CircularProgressIndicator());
              case HomeStatus.failure:
                return _ErrorView(
                  message: failureText(
                      context, state.failure ?? AppFailure.generic),
                  onRetry: () =>
                      context.read<HomeBloc>().add(const HomeStarted()),
                );
              case HomeStatus.success:
                return _HomeContent(state: state);
            }
          },
        ),
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  final HomeState state;

  const _HomeContent({required this.state});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;
    return RefreshIndicator(
      onRefresh: () async =>
          context.read<HomeBloc>().add(const HomeStarted()),
      child: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.defaultMargin,
        ),
        children: [
          const SizedBox(height: 8),
          const _AppBar(),
          const SizedBox(height: 24),
          if (state.account != null) BalanceCard(account: state.account!),
          const SizedBox(height: 24),
          const _SearchBar(),
          const SizedBox(height: 28),
          const _PlanAheadCard(),
          const SizedBox(height: 28),
          Text(
            l10n.homeShortcut,
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          for (final shortcut in state.shortcuts)
            ShortcutCard(
              shortcut: shortcut,
              onTap: switch (shortcut.name) {
                'Kirim & Bayar' => () => context.push(AppRouter.transfer),
                'Pulsa & Data' => () => context.push(AppRouter.topup),
                _ => null,
              },
            ),
          const SizedBox(height: 28),
          Text(
            l10n.homeRecentTransactions,
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          for (final tx in state.recentTransactions)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: tx.isIncome
                    ? AppColors.success.withValues(alpha: 0.12)
                    : AppColors.primaryLight,
                child: Icon(
                  tx.isIncome
                      ? Icons.south_west_rounded
                      : Icons.north_east_rounded,
                  color: tx.isIncome ? AppColors.success : AppColors.primary,
                ),
              ),
              title: Text(tx.title),
              subtitle: Text(tx.category),
              trailing: Text(
                '${tx.isIncome ? '+' : '-'}${CurrencyFormatter.format(tx.amount)}',
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: tx.isIncome
                      ? AppColors.success
                      : Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _AppBar extends StatelessWidget {
  const _AppBar();

  @override
  Widget build(BuildContext context) {
    final unread =
        context.select((NotificationsBloc bloc) => bloc.state.unreadCount);
    return Row(
      children: [
        Image.asset(AppAssets.logo, width: 100, height: 30),
        const Spacer(),
        IconButton(
          tooltip: AppLocalizations.of(context)!.homeQris,
          icon: const Icon(Icons.qr_code_scanner_rounded),
          onPressed: () => context.push(AppRouter.qris),
        ),
        InkWell(
          onTap: () => context.push(AppRouter.notifications),
          customBorder: const CircleBorder(),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Image.asset(AppAssets.iconNotification, width: 28, height: 28),
                if (unread > 0)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      constraints:
                          const BoxConstraints(minWidth: 18, minHeight: 18),
                      decoration: const BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        unread > 9 ? '9+' : '$unread',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar();

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push(AppRouter.transfer),
      borderRadius: BorderRadius.circular(AppTheme.defaultRadius),
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.defaultRadius),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppLocalizations.of(context)!.homeSearchHint,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.grey,
                    fontWeight: FontWeight.w500,
                  ),
            ),
            Image.asset(AppAssets.iconSearch, width: 16, height: 16),
          ],
        ),
      ),
    );
  }
}

class _PlanAheadCard extends StatelessWidget {
  const _PlanAheadCard();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.homePlanAhead,
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        InkWell(
          onTap: () => context.push(AppRouter.bills),
          borderRadius: BorderRadius.circular(AppTheme.defaultRadius),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.defaultRadius),
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant),
            ),
            child: Row(
              children: [
                Image.asset(AppAssets.tasks, width: 50, height: 50),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.homePlanAheadPrompt,
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        l10n.homePlanAheadCta,
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 48, color: AppColors.grey),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onRetry, child: const Text('Coba Lagi')),
          ],
        ),
      ),
    );
  }
}
