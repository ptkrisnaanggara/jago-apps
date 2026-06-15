import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jago/l10n/app_localizations.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../data/models/pocket.dart';
import '../../data/repositories/pocket_repository.dart';
import '../bloc/kantong_bloc.dart';

class KantongPage extends StatelessWidget {
  const KantongPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => KantongBloc(
        repository: context.read<PocketRepository>(),
      )..add(const KantongStarted()),
      child: const _KantongView(),
    );
  }
}

class _KantongView extends StatelessWidget {
  const _KantongView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.kantongTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        icon: const Icon(Icons.add),
        label: Text(l10n.kantongNew),
      ),
      body: SafeArea(
        child: BlocBuilder<KantongBloc, KantongState>(
          builder: (context, state) {
            switch (state.status) {
              case KantongStatus.initial:
              case KantongStatus.loading:
                return const Center(child: CircularProgressIndicator());
              case KantongStatus.failure:
                return Center(
                    child: Text(state.errorMessage ?? l10n.genericError));
              case KantongStatus.success:
                return ListView(
                  padding: const EdgeInsets.all(AppTheme.defaultMargin),
                  children: [
                    Text(
                      l10n.kantongTotal,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      CurrencyFormatter.format(state.totalBalance),
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 16),
                    for (var i = 0; i < state.pockets.length; i++)
                      _PocketTile(
                        pocket: state.pockets[i],
                        accent: AppColors.pocketAccent(i),
                      ),
                  ],
                );
            }
          },
        ),
      ),
    );
  }
}

class _PocketTile extends StatelessWidget {
  final Pocket pocket;
  final Color accent;

  const _PocketTile({required this.pocket, required this.accent});

  @override
  Widget build(BuildContext context) {
    final progress = pocket.progress;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.defaultRadius),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  pocket.isMain
                      ? Icons.account_balance_wallet_rounded
                      : Icons.savings_rounded,
                  color: accent,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  pocket.name,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                CurrencyFormatter.format(pocket.balance),
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          if (progress != null) ...[
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: Theme.of(context).colorScheme.outlineVariant,
                valueColor: AlwaysStoppedAnimation<Color>(accent),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              AppLocalizations.of(context)!
                  .kantongTarget(CurrencyFormatter.format(pocket.target!)),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}
