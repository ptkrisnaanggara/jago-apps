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
import '../../data/repositories/qris_repository.dart';
import '../bloc/qris_bloc.dart';

/// A demo QRIS payload (dynamic: merchant "Indomaret", amount 25.000).
const _sampleQris = '0002015909Indomaret6007Bandung540525000';

class QrisPage extends StatelessWidget {
  const QrisPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => QrisBloc(
        qris: context.read<QrisRepository>(),
        pockets: context.read<PocketRepository>(),
      )..add(const QrisStarted()),
      child: const _QrisView(),
    );
  }
}

class _QrisView extends StatefulWidget {
  const _QrisView();

  @override
  State<_QrisView> createState() => _QrisViewState();
}

class _QrisViewState extends State<_QrisView> {
  final _payload = TextEditingController();
  final _amount = TextEditingController();
  String? _pocketId;

  @override
  void dispose() {
    _payload.dispose();
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.qrisTitle)),
      body: SafeArea(
        child: BlocConsumer<QrisBloc, QrisState>(
          listenWhen: (prev, curr) =>
              curr.failure != null && prev.failure != curr.failure,
          listener: (context, state) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(failureText(context, state.failure!))),
            );
          },
          builder: (context, state) {
            switch (state.status) {
              case QrisStatus.initial:
              case QrisStatus.loading:
                return const Center(child: CircularProgressIndicator());
              case QrisStatus.failure:
                return Center(
                    child: Text(failureText(
                        context, state.failure ?? AppFailure.generic)));
              case QrisStatus.success:
                return _Receipt(receipt: state.receipt!);
              default:
                return state.info == null
                    ? _payloadStep(context, state, l10n)
                    : _reviewStep(context, state, l10n);
            }
          },
        ),
      ),
    );
  }

  Widget _payloadStep(BuildContext context, QrisState state, AppLocalizations l10n) {
    final busy = state.status == QrisStatus.parsing;
    return ListView(
      padding: const EdgeInsets.all(AppTheme.defaultMargin),
      children: [
        const Icon(Icons.qr_code_scanner_rounded, size: 64, color: AppColors.primary),
        const SizedBox(height: 24),
        TextField(
          controller: _payload,
          minLines: 2,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: l10n.qrisPayloadLabel,
            border: const OutlineInputBorder(),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => _payload.text = _sampleQris,
            child: Text(l10n.qrisUseSample),
          ),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: busy || _payload.text.trim().isEmpty
              ? null
              : () => context
                  .read<QrisBloc>()
                  .add(QrisParseRequested(_payload.text.trim())),
          child: busy
              ? const _Spinner()
              : Text(l10n.actionNext),
        ),
      ],
    );
  }

  Widget _reviewStep(BuildContext context, QrisState state, AppLocalizations l10n) {
    final info = state.info!;
    final busy = state.status == QrisStatus.paying;
    final pocketId = _pocketId ??
        (state.pockets.isNotEmpty ? state.pockets.first.id : null);

    return ListView(
      padding: const EdgeInsets.all(AppTheme.defaultMargin),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(AppTheme.defaultRadius),
          ),
          child: Row(
            children: [
              const Icon(Icons.storefront_rounded, color: AppColors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(info.merchantName,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    if (info.merchantCity.isNotEmpty)
                      Text(info.merchantCity,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: AppColors.grey)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (info.dynamic_)
          Text(
            CurrencyFormatter.format(info.amount),
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .headlineMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          )
        else
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
        const SizedBox(height: 20),
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
                    child: Text('${p.name} · ${CurrencyFormatter.format(p.balance)}',
                        overflow: TextOverflow.ellipsis),
                  ),
              ],
              onChanged: (v) => setState(() => _pocketId = v),
            ),
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: busy ? null : () => _pay(context, info, pocketId),
          child: busy ? const _Spinner() : Text(l10n.qrisPayAction),
        ),
      ],
    );
  }

  void _pay(BuildContext context, info, String? pocketId) {
    double? amount;
    if (!info.dynamic_) {
      amount = double.tryParse(_amount.text.trim());
      if (amount == null || amount <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.amountInvalid)),
        );
        return;
      }
    }
    context.read<QrisBloc>().add(QrisPaid(pocketId: pocketId, amount: amount));
  }
}

class _Spinner extends StatelessWidget {
  const _Spinner();

  @override
  Widget build(BuildContext context) => const SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white),
      );
}

class _Receipt extends StatelessWidget {
  final dynamic receipt;

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
          Text(l10n.qrisSuccessTitle,
              style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(CurrencyFormatter.format(receipt.amount),
              style: textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppTheme.defaultRadius),
            ),
            child: Column(
              children: [
                _row(context, l10n.qrisMerchantLabel, receipt.merchantName as String),
                _row(context, l10n.qrisPayFrom, receipt.pocketName as String),
                _row(context, l10n.fieldReferenceNo, receipt.referenceId as String),
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
                style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
