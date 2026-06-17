import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:jago/l10n/app_localizations.dart';

import '../../../../core/errors/app_failure.dart';
import '../../../../core/errors/failure_l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../kantong/data/repositories/pocket_repository.dart';
import '../../data/models/topup_models.dart';
import '../../data/repositories/topup_repository.dart';
import '../bloc/topup_bloc.dart';

class TopupPage extends StatelessWidget {
  const TopupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => TopupBloc(
        topup: context.read<TopupRepository>(),
        pockets: context.read<PocketRepository>(),
      )..add(const TopupStarted()),
      child: const _TopupView(),
    );
  }
}

class _TopupView extends StatefulWidget {
  const _TopupView();

  @override
  State<_TopupView> createState() => _TopupViewState();
}

class _TopupViewState extends State<_TopupView> {
  final _phone = TextEditingController();
  String _type = 'pulsa';
  String? _productId;
  String? _pocketId;

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.topupTitle)),
      body: SafeArea(
        child: BlocConsumer<TopupBloc, TopupState>(
          listenWhen: (prev, curr) =>
              curr.failure != null && prev.failure != curr.failure,
          listener: (context, state) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(failureText(context, state.failure!))),
            );
          },
          builder: (context, state) {
            switch (state.status) {
              case TopupStatus.initial:
              case TopupStatus.loading:
                return const Center(child: CircularProgressIndicator());
              case TopupStatus.failure:
                return Center(
                    child: Text(failureText(
                        context, state.failure ?? AppFailure.generic)));
              case TopupStatus.success:
                return _Receipt(receipt: state.receipt!);
              default:
                return _form(context, state, l10n);
            }
          },
        ),
      ),
    );
  }

  Widget _form(BuildContext context, TopupState state, AppLocalizations l10n) {
    final busy = state.status == TopupStatus.purchasing;
    final products = state.products.where((p) => p.type == _type).toList();
    final pocketId =
        _pocketId ?? (state.pockets.isNotEmpty ? state.pockets.first.id : null);

    return ListView(
      padding: const EdgeInsets.all(AppTheme.defaultMargin),
      children: [
        TextField(
          controller: _phone,
          keyboardType: TextInputType.phone,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            labelText: l10n.phoneLabel,
            prefixText: '+62 ',
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        SegmentedButton<String>(
          segments: [
            ButtonSegment(value: 'pulsa', label: Text(l10n.topupTabPulsa)),
            ButtonSegment(value: 'data', label: Text(l10n.topupTabData)),
          ],
          selected: {_type},
          onSelectionChanged: (s) => setState(() {
            _type = s.first;
            _productId = null;
          }),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final p in products)
              ChoiceChip(
                label: Text('${p.name} · ${CurrencyFormatter.format(p.amount)}'),
                selected: _productId == p.id,
                onSelected: (_) => setState(() => _productId = p.id),
              ),
          ],
        ),
        const SizedBox(height: 16),
        InputDecorator(
          decoration: InputDecoration(
            labelText: l10n.qrisPayFrom,
            border: const OutlineInputBorder(),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: pocketId,
              items: [
                for (final p in state.pockets)
                  DropdownMenuItem(
                    value: p.id,
                    child: Text(
                        '${p.name} · ${CurrencyFormatter.format(p.balance)}',
                        overflow: TextOverflow.ellipsis),
                  ),
              ],
              onChanged: (v) => setState(() => _pocketId = v),
            ),
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: busy ? null : () => _buy(context, pocketId),
          child: busy
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppColors.white))
              : Text(l10n.topupBuy),
        ),
      ],
    );
  }

  void _buy(BuildContext context, String? pocketId) {
    final phone = _phone.text.trim();
    final productId = _productId;
    if (phone.isEmpty || productId == null) return;
    context.read<TopupBloc>().add(TopupPurchased(
          productId: productId,
          phone: phone,
          pocketId: pocketId,
        ));
  }
}

class _Receipt extends StatelessWidget {
  final TopupReceipt receipt;

  const _Receipt({required this.receipt});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final time = DateFormat('d MMM yyyy, HH:mm', 'id_ID').format(receipt.paidAt);
    return Padding(
      padding: const EdgeInsets.all(AppTheme.defaultMargin),
      child: Column(
        children: [
          const Spacer(),
          const CircleAvatar(
            radius: 44,
            backgroundColor: AppColors.success,
            child: Icon(Icons.check_rounded, size: 52, color: AppColors.white),
          ),
          const SizedBox(height: 20),
          Text(l10n.topupSuccessTitle,
              style:
                  textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(CurrencyFormatter.format(receipt.amount),
              style: textTheme.headlineMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppTheme.defaultRadius),
            ),
            child: Column(
              children: [
                _row(context, l10n.topupTitle, receipt.productName),
                _row(context, l10n.phoneLabel, '+62 ${receipt.phone}'),
                _row(context, l10n.qrisPayFrom, receipt.pocketName),
                _row(context, l10n.fieldReferenceNo, receipt.referenceId),
                _row(context, l10n.fieldTime, time),
              ],
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.actionDone),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label,
                style: textTheme.bodyMedium?.copyWith(color: AppColors.grey)),
          ),
          Expanded(
            child: Text(value,
                textAlign: TextAlign.right,
                style:
                    textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
