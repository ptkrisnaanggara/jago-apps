import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jago/l10n/app_localizations.dart';

import '../../../../core/errors/app_failure.dart';
import '../../../../core/errors/failure_l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../data/models/pocket.dart';
import '../../data/repositories/pocket_repository.dart';
import '../bloc/kantong_bloc.dart';

String pocketTypeLabel(AppLocalizations l10n, PocketType type) => switch (type) {
      PocketType.main => l10n.pocketTypeMain,
      PocketType.spending => l10n.pocketTypeSpending,
      PocketType.saving => l10n.pocketTypeSaving,
    };

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
      appBar: AppBar(
        title: Text(l10n.kantongTitle),
        actions: [
          BlocBuilder<KantongBloc, KantongState>(
            builder: (context, state) {
              if (state.pockets.length < 2) return const SizedBox.shrink();
              return IconButton(
                tooltip: l10n.moveMoneyTitle,
                icon: const Icon(Icons.swap_horiz_rounded),
                onPressed: () => _showMoveSheet(context, state.pockets),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateSheet(context),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        icon: const Icon(Icons.add),
        label: Text(l10n.kantongNew),
      ),
      body: SafeArea(
        child: BlocConsumer<KantongBloc, KantongState>(
          listenWhen: (prev, curr) =>
              curr.status == KantongStatus.success &&
              curr.failure != null &&
              prev.failure != curr.failure,
          listener: (context, state) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(failureText(context, state.failure!))),
            );
          },
          builder: (context, state) {
            switch (state.status) {
              case KantongStatus.initial:
              case KantongStatus.loading:
                return const Center(child: CircularProgressIndicator());
              case KantongStatus.failure:
                return Center(
                    child: Text(failureText(
                        context, state.failure ?? AppFailure.generic)));
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

  void _showCreateSheet(BuildContext context) {
    final bloc = context.read<KantongBloc>();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: const _CreatePocketSheet(),
      ),
    );
  }

  void _showMoveSheet(BuildContext context, List<Pocket> pockets) {
    final bloc = context.read<KantongBloc>();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: _MovePocketSheet(pockets: pockets),
      ),
    );
  }
}

class _CreatePocketSheet extends StatefulWidget {
  const _CreatePocketSheet();

  @override
  State<_CreatePocketSheet> createState() => _CreatePocketSheetState();
}

class _CreatePocketSheetState extends State<_CreatePocketSheet> {
  final _name = TextEditingController();
  final _target = TextEditingController();
  PocketType _type = PocketType.spending;

  @override
  void dispose() {
    _name.dispose();
    _target.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    final target = double.tryParse(_target.text.trim());
    context.read<KantongBloc>().add(KantongPocketCreated(
          name: name,
          type: _type,
          target: _type == PocketType.saving ? target : null,
        ));
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
          Text(l10n.kantongNew,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: l10n.pocketNameLabel,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Text(l10n.pocketTypeLabel,
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 4),
          SegmentedButton<PocketType>(
            segments: [
              ButtonSegment(
                  value: PocketType.spending,
                  label: Text(l10n.pocketTypeSpending)),
              ButtonSegment(
                  value: PocketType.saving, label: Text(l10n.pocketTypeSaving)),
            ],
            selected: {_type},
            onSelectionChanged: (s) => setState(() => _type = s.first),
          ),
          if (_type == PocketType.saving) ...[
            const SizedBox(height: 16),
            TextField(
              controller: _target,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: l10n.pocketTargetOptional,
                prefixText: 'Rp ',
                border: const OutlineInputBorder(),
              ),
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submit,
              child: Text(l10n.createPocketAction),
            ),
          ),
        ],
      ),
    );
  }
}

class _MovePocketSheet extends StatefulWidget {
  final List<Pocket> pockets;

  const _MovePocketSheet({required this.pockets});

  @override
  State<_MovePocketSheet> createState() => _MovePocketSheetState();
}

class _MovePocketSheetState extends State<_MovePocketSheet> {
  final _amount = TextEditingController();
  late Pocket _from = widget.pockets.first;
  late Pocket _to = widget.pockets[1];

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  void _submit() {
    final amount = double.tryParse(_amount.text.trim()) ?? 0;
    if (_from.id == _to.id || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.amountInvalid)),
      );
      return;
    }
    context.read<KantongBloc>().add(KantongMoneyMoved(
          fromId: _from.id,
          toId: _to.id,
          amount: amount,
        ));
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
          Text(l10n.moveMoneyTitle,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          _pocketDropdown(l10n.moveFromLabel, _from,
              (p) => setState(() => _from = p)),
          const SizedBox(height: 12),
          _pocketDropdown(
              l10n.moveToLabel, _to, (p) => setState(() => _to = p)),
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
              onPressed: _submit,
              child: Text(l10n.moveAction),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pocketDropdown(
      String label, Pocket selected, ValueChanged<Pocket> onChanged) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Pocket>(
          isExpanded: true,
          value: selected,
          items: [
            for (final p in widget.pockets)
              DropdownMenuItem(
                value: p,
                child: Text(
                  '${p.name} · ${CurrencyFormatter.format(p.balance)}',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          onChanged: (p) {
            if (p != null) onChanged(p);
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
    final l10n = AppLocalizations.of(context)!;
    final progress = pocket.progress;
    return InkWell(
      borderRadius: BorderRadius.circular(AppTheme.defaultRadius),
      onTap: pocket.isMain ? null : () => _showActions(context),
      child: Container(
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pocket.name,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    Row(
                      children: [
                        Text(
                          pocketTypeLabel(l10n, pocket.type),
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: AppColors.grey),
                        ),
                        if (pocket.locked) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.lock_rounded,
                              size: 13, color: AppColors.grey),
                        ],
                        if (pocket.hasAutosave) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.autorenew_rounded,
                              size: 13, color: AppColors.primary),
                        ],
                        if (pocket.shared) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.group_rounded,
                              size: 13, color: AppColors.primary),
                          const SizedBox(width: 3),
                          Text(l10n.pocketSharedBadge,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(color: AppColors.primary)),
                        ],
                      ],
                    ),
                  ],
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
              l10n.kantongTarget(CurrencyFormatter.format(pocket.target!)),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
      ),
    );
  }

  void _showActions(BuildContext context) {
    final bloc = context.read<KantongBloc>();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: _PocketActionsSheet(pocket: pocket),
      ),
    );
  }
}

class _PocketActionsSheet extends StatefulWidget {
  final Pocket pocket;

  const _PocketActionsSheet({required this.pocket});

  @override
  State<_PocketActionsSheet> createState() => _PocketActionsSheetState();
}

class _PocketActionsSheetState extends State<_PocketActionsSheet> {
  late final _amount = TextEditingController(
    text: widget.pocket.autosaveAmount > 0
        ? widget.pocket.autosaveAmount.round().toString()
        : '',
  );
  late String _freq = widget.pocket.autosaveFrequency == 'none'
      ? 'weekly'
      : widget.pocket.autosaveFrequency;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final p = widget.pocket;
    final freqLabels = {
      'daily': l10n.autosaveDaily,
      'weekly': l10n.autosaveWeekly,
      'monthly': l10n.autosaveMonthly,
    };
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
          Text('${l10n.pocketManage} · ${p.name}',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          // Owner-only actions: lock, autosave, share.
          if (!p.isMember) ...[
            OutlinedButton.icon(
              onPressed: () {
                context
                    .read<KantongBloc>()
                    .add(KantongLockToggled(id: p.id, locked: !p.locked));
                Navigator.pop(context);
              },
              icon: Icon(
                  p.locked ? Icons.lock_open_rounded : Icons.lock_rounded),
              label: Text(p.locked ? l10n.pocketUnlock : l10n.pocketLock),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => _promptShare(context),
              icon: const Icon(Icons.group_add_rounded),
              label: Text(l10n.pocketShare),
            ),
            const SizedBox(height: 20),
            Text(l10n.autosaveTitle,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
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
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: [
                for (final e in freqLabels.entries)
                  ButtonSegment(value: e.key, label: Text(e.value)),
              ],
              selected: {_freq},
              onSelectionChanged: (s) => setState(() => _freq = s.first),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      final amt = double.tryParse(_amount.text.trim()) ?? 0;
                      context.read<KantongBloc>().add(KantongAutosaveSet(
                          id: p.id, amount: amt, frequency: _freq));
                      Navigator.pop(context);
                    },
                    child: Text(l10n.autosaveSave),
                  ),
                ),
                if (p.hasAutosave) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        context
                            .read<KantongBloc>()
                            .add(KantongAutosaveRun(p.id));
                        Navigator.pop(context);
                      },
                      child: Text(l10n.autosaveRun),
                    ),
                  ),
                ],
              ],
            ),
          ],
          // Shared pocket: deposit + members (visible to owner & members).
          if (p.shared || p.isMember) ...[
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => _promptDeposit(context),
              icon: const Icon(Icons.savings_rounded),
              label: Text(l10n.pocketDeposit),
            ),
            const SizedBox(height: 12),
            Text(l10n.pocketMembers,
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600)),
            _MembersList(pocketId: p.id),
          ],
        ],
      ),
    );
  }

  Future<void> _promptShare(BuildContext context) async {
    final bloc = context.read<KantongBloc>();
    final l10n = AppLocalizations.of(context)!;
    final phone = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: Text(l10n.pocketShare),
        content: TextField(
          controller: phone,
          keyboardType: TextInputType.phone,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            labelText: l10n.phoneLabel,
            prefixText: '+62 ',
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(d, false),
              child: Text(l10n.actionCancel)),
          TextButton(
              onPressed: () => Navigator.pop(d, true),
              child: Text(l10n.pocketShare)),
        ],
      ),
    );
    if (ok == true && phone.text.trim().isNotEmpty) {
      bloc.add(KantongPocketShared(
          id: widget.pocket.id, phone: phone.text.trim()));
      if (context.mounted) Navigator.pop(context);
    }
  }

  Future<void> _promptDeposit(BuildContext context) async {
    final bloc = context.read<KantongBloc>();
    final l10n = AppLocalizations.of(context)!;
    final amount = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: Text(l10n.pocketDeposit),
        content: TextField(
          controller: amount,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
              labelText: l10n.amountLabel, prefixText: 'Rp '),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(d, false),
              child: Text(l10n.actionCancel)),
          TextButton(
              onPressed: () => Navigator.pop(d, true),
              child: Text(l10n.pocketDeposit)),
        ],
      ),
    );
    final amt = double.tryParse(amount.text.trim()) ?? 0;
    if (ok == true && amt > 0) {
      bloc.add(KantongDeposited(id: widget.pocket.id, amount: amt));
      if (context.mounted) Navigator.pop(context);
    }
  }
}

class _MembersList extends StatelessWidget {
  final String pocketId;

  const _MembersList({required this.pocketId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: context.read<PocketRepository>().members(pocketId),
      builder: (context, snapshot) {
        final members = snapshot.data ?? const [];
        return Column(
          children: [
            for (final m in members)
              ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                leading: const Icon(Icons.person_rounded, color: AppColors.grey),
                title: Text(m.name),
                trailing: Text(m.role,
                    style: Theme.of(context)
                        .textTheme
                        .labelSmall
                        ?.copyWith(color: AppColors.grey)),
              ),
          ],
        );
      },
    );
  }
}
