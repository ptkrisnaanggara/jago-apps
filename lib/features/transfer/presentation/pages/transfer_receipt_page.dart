import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../bloc/transfer_bloc.dart';

/// Step 3 of the Transfer & Pay flow: success receipt.
class TransferReceiptPage extends StatelessWidget {
  const TransferReceiptPage({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final result = context.select((TransferBloc b) => b.state.result);

    if (result == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Tidak ada data transaksi.')),
      );
    }

    final dateLabel =
        DateFormat('d MMM yyyy, HH:mm', 'id_ID').format(result.timestamp);

    return Scaffold(
      body: SafeArea(
        child: Padding(
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
              Text(
                'Transfer Berhasil',
                style:
                    textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                CurrencyFormatter.format(result.amount),
                style: textTheme.headlineMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.lightGrey,
                  borderRadius: BorderRadius.circular(AppTheme.defaultRadius),
                ),
                child: Column(
                  children: [
                    _ReceiptRow(label: 'Penerima', value: result.contact.name),
                    _ReceiptRow(
                      label: 'Bank',
                      value:
                          '${result.contact.bankName} • ${result.contact.accountNumber}',
                    ),
                    if (result.note.isNotEmpty)
                      _ReceiptRow(label: 'Catatan', value: result.note),
                    _ReceiptRow(label: 'No. Referensi', value: result.referenceId),
                    _ReceiptRow(label: 'Waktu', value: dateLabel),
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.go(AppRouter.home),
                  child: const Text('Selesai'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReceiptRow extends StatelessWidget {
  final String label;
  final String value;

  const _ReceiptRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
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
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
