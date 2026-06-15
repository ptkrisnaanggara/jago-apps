import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:jago/l10n/app_localizations.dart';

import '../../../../core/errors/app_failure.dart';
import '../../../../core/errors/failure_l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../data/models/transaction.dart';
import '../../data/repositories/transaction_repository.dart';
import '../bloc/transactions_bloc.dart';

class TransactionsPage extends StatelessWidget {
  const TransactionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => TransactionsBloc(
        repository: context.read<TransactionRepository>(),
      )..add(const TransactionsStarted()),
      child: const _TransactionsView(),
    );
  }
}

class _TransactionsView extends StatelessWidget {
  const _TransactionsView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.transactionsTitle)),
      body: SafeArea(
        child: BlocBuilder<TransactionsBloc, TransactionsState>(
          builder: (context, state) {
            switch (state.status) {
              case TransactionsStatus.initial:
              case TransactionsStatus.loading:
                return const Center(child: CircularProgressIndicator());
              case TransactionsStatus.failure:
                return Center(
                    child: Text(failureText(
                        context, state.failure ?? AppFailure.generic)));
              case TransactionsStatus.success:
                if (state.transactions.isEmpty) {
                  return Center(child: Text(l10n.transactionsEmpty));
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(AppTheme.defaultMargin),
                  itemCount: state.transactions.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) =>
                      _TransactionTile(item: state.transactions[index]),
                );
            }
          },
        ),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final TransactionItem item;

  const _TransactionTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: item.isIncome
            ? AppColors.success.withValues(alpha: 0.12)
            : AppColors.primaryLight,
        child: Icon(
          item.isIncome ? Icons.south_west_rounded : Icons.north_east_rounded,
          color: item.isIncome ? AppColors.success : AppColors.primary,
        ),
      ),
      title: Text(item.title),
      subtitle: Text(
        '${item.category} · ${DateFormat('d MMM', 'id_ID').format(item.date)}',
      ),
      trailing: Text(
        '${item.isIncome ? '+' : '-'}${CurrencyFormatter.format(item.amount)}',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: item.isIncome
                  ? AppColors.success
                  : Theme.of(context).colorScheme.onSurface,
            ),
      ),
    );
  }
}
