import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jago/l10n/app_localizations.dart';

import '../../../../core/errors/app_failure.dart';
import '../../../../core/errors/failure_l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../data/models/pool_models.dart';
import '../../data/repositories/pool_repository.dart';
import '../bloc/pool_detail_bloc.dart';

class PoolDetailPage extends StatelessWidget {
  final String poolId;

  const PoolDetailPage({super.key, required this.poolId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          PoolDetailBloc(repository: context.read<PoolRepository>())
            ..add(PoolDetailStarted(poolId)),
      child: const _PoolDetailView(),
    );
  }
}

class _PoolDetailView extends StatelessWidget {
  const _PoolDetailView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.poolTitle)),
      body: SafeArea(
        child: BlocConsumer<PoolDetailBloc, PoolDetailState>(
          listenWhen: (p, c) => c.failure != null && p.failure != c.failure,
          listener: (context, state) =>
              ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(failureText(context, state.failure!))),
          ),
          builder: (context, state) {
            if (state.detail == null) {
              if (state.status == PoolDetailStatus.failure) {
                return Center(
                    child: Text(failureText(
                        context, state.failure ?? AppFailure.generic)));
              }
              return const Center(child: CircularProgressIndicator());
            }
            return _content(context, state.detail!, l10n);
          },
        ),
      ),
    );
  }

  Widget _content(BuildContext context, PoolDetail d, AppLocalizations l10n) {
    final pool = d.pool;
    final textTheme = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.all(AppTheme.defaultMargin),
      children: [
        Text(pool.title,
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: pool.progress,
            minHeight: 8,
            backgroundColor: Theme.of(context).colorScheme.outlineVariant,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${CurrencyFormatter.format(pool.collected)} / ${CurrencyFormatter.format(pool.target)}',
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 20),
        if (pool.isOpen)
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showContributeSheet(context),
                  icon: const Icon(Icons.add),
                  label: Text(l10n.poolContribute),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () =>
                      context.read<PoolDetailBloc>().add(const PoolClosed()),
                  icon: const Icon(Icons.savings_rounded),
                  label: Text(l10n.poolClose),
                ),
              ),
            ],
          )
        else
          Align(
            alignment: Alignment.centerLeft,
            child: Text(l10n.poolClosed,
                style: textTheme.titleMedium?.copyWith(color: AppColors.grey)),
          ),
        const SizedBox(height: 24),
        if (d.contributions.isNotEmpty)
          for (final c in d.contributions)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: AppColors.primaryLight,
                child: Text(
                  c.name.isNotEmpty ? c.name[0].toUpperCase() : '?',
                  style: const TextStyle(
                      color: AppColors.primary, fontWeight: FontWeight.w700),
                ),
              ),
              title: Text(c.name),
              trailing: Text(
                CurrencyFormatter.format(c.amount),
                style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
      ],
    );
  }

  void _showContributeSheet(BuildContext context) {
    final bloc = context.read<PoolDetailBloc>();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) =>
          BlocProvider.value(value: bloc, child: const _ContributeSheet()),
    );
  }
}

class _ContributeSheet extends StatefulWidget {
  const _ContributeSheet();

  @override
  State<_ContributeSheet> createState() => _ContributeSheetState();
}

class _ContributeSheetState extends State<_ContributeSheet> {
  final _name = TextEditingController();
  final _amount = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _name.text.trim();
    final amount = double.tryParse(_amount.text.trim()) ?? 0;
    if (name.isEmpty || amount <= 0) return;
    context.read<PoolDetailBloc>().add(PoolContributed(name: name, amount: amount));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: EdgeInsets.only(
        left: AppTheme.defaultMargin,
        right: AppTheme.defaultMargin,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.poolContribute,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: l10n.poolContributorLabel,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _amount,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: l10n.amountLabel,
              prefixText: 'Rp ',
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
                onPressed: _submit, child: Text(l10n.poolContribute)),
          ),
        ],
      ),
    );
  }
}
