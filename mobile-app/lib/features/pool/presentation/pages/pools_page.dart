import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/app_failure.dart';
import '../../../../core/errors/failure_l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/currency_formatter.dart';
import 'package:jago/l10n/app_localizations.dart';
import '../../data/models/pool_models.dart';
import '../../data/repositories/pool_repository.dart';
import '../bloc/pools_bloc.dart';
import 'pool_detail_page.dart';

class PoolsPage extends StatelessWidget {
  const PoolsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          PoolsBloc(repository: context.read<PoolRepository>())
            ..add(const PoolsStarted()),
      child: const _PoolsView(),
    );
  }
}

class _PoolsView extends StatelessWidget {
  const _PoolsView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.poolTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateSheet(context),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        icon: const Icon(Icons.add),
        label: Text(l10n.poolNew),
      ),
      body: SafeArea(
        child: BlocConsumer<PoolsBloc, PoolsState>(
          listenWhen: (p, c) =>
              c.status == PoolsStatus.success &&
              c.failure != null &&
              p.failure != c.failure,
          listener: (context, state) =>
              ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(failureText(context, state.failure!))),
          ),
          builder: (context, state) {
            switch (state.status) {
              case PoolsStatus.initial:
              case PoolsStatus.loading:
                return const Center(child: CircularProgressIndicator());
              case PoolsStatus.failure:
                return Center(
                    child: Text(failureText(
                        context, state.failure ?? AppFailure.generic)));
              case PoolsStatus.success:
                if (state.pools.isEmpty) {
                  return Center(child: Text(l10n.poolEmpty));
                }
                return ListView(
                  padding: const EdgeInsets.all(AppTheme.defaultMargin),
                  children: [
                    for (final pool in state.pools)
                      _PoolCard(pool: pool, bloc: context.read<PoolsBloc>()),
                  ],
                );
            }
          },
        ),
      ),
    );
  }

  void _showCreateSheet(BuildContext context) {
    final bloc = context.read<PoolsBloc>();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) =>
          BlocProvider.value(value: bloc, child: const _CreatePoolSheet()),
    );
  }
}

class _PoolCard extends StatelessWidget {
  final MoneyPool pool;
  final PoolsBloc bloc;

  const _PoolCard({required this.pool, required this.bloc});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppTheme.defaultRadius),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(pool.title,
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: pool.progress,
                minHeight: 6,
                backgroundColor: Theme.of(context).colorScheme.outlineVariant,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${CurrencyFormatter.format(pool.collected)} / ${CurrencyFormatter.format(pool.target)}',
              style: textTheme.bodySmall,
            ),
          ],
        ),
        trailing: Text(
          pool.isOpen ? l10n.poolOpen : l10n.poolClosed,
          style: textTheme.labelSmall?.copyWith(
            color: pool.isOpen ? AppColors.success : AppColors.grey,
            fontWeight: FontWeight.w600,
          ),
        ),
        onTap: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => PoolDetailPage(poolId: pool.id)),
          );
          // Refresh the list to reflect contributions / close on return.
          bloc.add(const PoolsStarted());
        },
      ),
    );
  }
}

class _CreatePoolSheet extends StatefulWidget {
  const _CreatePoolSheet();

  @override
  State<_CreatePoolSheet> createState() => _CreatePoolSheetState();
}

class _CreatePoolSheetState extends State<_CreatePoolSheet> {
  final _title = TextEditingController();
  final _target = TextEditingController();

  @override
  void dispose() {
    _title.dispose();
    _target.dispose();
    super.dispose();
  }

  void _submit() {
    final title = _title.text.trim();
    final target = double.tryParse(_target.text.trim()) ?? 0;
    if (title.isEmpty || target <= 0) return;
    context.read<PoolsBloc>().add(PoolCreated(title: title, target: target));
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
          Text(l10n.poolNew,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          TextField(
            controller: _title,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: l10n.poolTitleLabel,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _target,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: l10n.poolTargetLabel,
              prefixText: 'Rp ',
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
                onPressed: _submit, child: Text(l10n.poolCreate)),
          ),
        ],
      ),
    );
  }
}
