import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:jago/l10n/app_localizations.dart';

import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../data/models/bill.dart';
import '../bloc/bills_bloc.dart';
import '../recurrence_l10n.dart';

/// Bills & Payment Plans: upcoming + paid bills, with quick pay and a
/// "Rencana Baru" entry point to schedule a recurring bill.
class BillsPage extends StatelessWidget {
  const BillsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.billsTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRouter.billNew),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        icon: const Icon(Icons.add),
        label: Text(l10n.billsNewPlan),
      ),
      body: SafeArea(
        child: BlocConsumer<BillsBloc, BillsState>(
          // Surface pay/schedule errors as a snackbar; a load failure has its
          // own full-screen error view, so skip the snackbar in that case.
          listenWhen: (prev, curr) =>
              curr.status == BillsStatus.success &&
              curr.errorMessage != null &&
              prev.errorMessage != curr.errorMessage,
          listener: (context, state) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage!)),
            );
          },
          builder: (context, state) {
            switch (state.status) {
              case BillsStatus.initial:
              case BillsStatus.loading:
                return const Center(child: CircularProgressIndicator());
              case BillsStatus.failure:
                return _ErrorView(
                  message: state.errorMessage ?? l10n.genericError,
                  onRetry: () =>
                      context.read<BillsBloc>().add(const BillsStarted()),
                );
              case BillsStatus.success:
                return _BillsContent(state: state);
            }
          },
        ),
      ),
    );
  }
}

class _BillsContent extends StatelessWidget {
  final BillsState state;

  const _BillsContent({required this.state});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;
    final upcoming = state.upcomingBills;
    final paid = state.paidBills;

    return ListView(
      padding: const EdgeInsets.all(AppTheme.defaultMargin),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(AppTheme.defaultRadius),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // The card stays light-orange in both themes, so pin text dark.
              Text(l10n.billsTotalUpcoming,
                  style: textTheme.bodyMedium?.copyWith(color: AppColors.black)),
              const SizedBox(height: 4),
              Text(
                CurrencyFormatter.format(state.totalUpcoming),
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.black,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        if (upcoming.isEmpty)
          _EmptyHint(
            icon: Icons.check_circle_outline_rounded,
            text: l10n.billsEmptyUpcoming,
          )
        else ...[
          Text(l10n.billsUpcoming,
              style:
                  textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          for (final bill in upcoming)
            _BillTile(bill: bill, paying: state.payingId == bill.id),
        ],
        if (paid.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text(l10n.billsPaid,
              style:
                  textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          for (final bill in paid) _BillTile(bill: bill, paying: false),
        ],
        const SizedBox(height: 80),
      ],
    );
  }
}

class _BillTile extends StatelessWidget {
  final Bill bill;
  final bool paying;

  const _BillTile({required this.bill, required this.paying});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;
    final dueLabel = DateFormat('d MMM yyyy', 'id_ID').format(bill.dueDate);
    final accent = bill.isOverdue ? AppColors.error : AppColors.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppTheme.defaultRadius),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_iconFor(bill.category), color: accent),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(bill.biller,
                    style: textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      bill.isOverdue
                          ? l10n.billOverdue(dueLabel)
                          : l10n.billDue(dueLabel),
                      style: textTheme.bodySmall?.copyWith(
                        color: bill.isOverdue ? AppColors.error : AppColors.grey,
                      ),
                    ),
                    if (bill.isRecurring) ...[
                      const SizedBox(width: 6),
                      _Chip(label: recurrenceLabel(l10n, bill.recurrence)),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  CurrencyFormatter.format(bill.amount),
                  style: textTheme.bodyLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (bill.isPaid)
            const Icon(Icons.check_circle_rounded, color: AppColors.success)
          else
            SizedBox(
              height: 36,
              child: ElevatedButton(
                onPressed: paying
                    ? null
                    : () => context.read<BillsBloc>().add(BillPaid(bill.id)),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                child: paying
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.white,
                        ),
                      )
                    : Text(l10n.billsPay),
              ),
            ),
        ],
      ),
    );
  }

  static IconData _iconFor(String category) {
    switch (category) {
      case 'Listrik':
        return Icons.bolt_rounded;
      case 'Internet':
        return Icons.wifi_rounded;
      case 'Air':
        return Icons.water_drop_rounded;
      case 'Asuransi':
        return Icons.health_and_safety_rounded;
      case 'Telepon':
        return Icons.smartphone_rounded;
      default:
        return Icons.receipt_long_rounded;
    }
  }
}

class _Chip extends StatelessWidget {
  final String label;

  const _Chip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  final IconData icon;
  final String text;

  const _EmptyHint({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Icon(icon, size: 40, color: AppColors.grey),
          const SizedBox(height: 8),
          Text(text, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
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
            ElevatedButton(
                onPressed: onRetry,
                child: Text(AppLocalizations.of(context)!.actionRetry)),
          ],
        ),
      ),
    );
  }
}
