import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../bloc/transfer_bloc.dart';

/// Step 2 of the Transfer & Pay flow: enter the amount + note, then confirm.
class TransferAmountPage extends StatefulWidget {
  const TransferAmountPage({super.key});

  @override
  State<TransferAmountPage> createState() => _TransferAmountPageState();
}

class _TransferAmountPageState extends State<TransferAmountPage> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  double get _amount => double.tryParse(_amountController.text.trim()) ?? 0;

  void _onContinue() {
    if (_amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan nominal yang valid.')),
      );
      return;
    }
    context.read<TransferBloc>().add(
          TransferDetailsEntered(
            amount: _amount,
            note: _noteController.text.trim(),
          ),
        );
    _showConfirmSheet();
  }

  void _showConfirmSheet() {
    final bloc = context.read<TransferBloc>();
    final contact = bloc.state.selectedContact;
    if (contact == null) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return BlocProvider.value(
          value: bloc,
          child: Padding(
            padding: EdgeInsets.only(
              left: AppTheme.defaultMargin,
              right: AppTheme.defaultMargin,
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24,
              top: 8,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Konfirmasi Transfer',
                  style: Theme.of(sheetContext)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 16),
                _SummaryRow(label: 'Penerima', value: contact.name),
                _SummaryRow(
                    label: 'Bank',
                    value: '${contact.bankName} • ${contact.accountNumber}'),
                _SummaryRow(
                  label: 'Nominal',
                  value: CurrencyFormatter.format(_amount),
                  emphasize: true,
                ),
                if (_noteController.text.trim().isNotEmpty)
                  _SummaryRow(label: 'Catatan', value: _noteController.text.trim()),
                const SizedBox(height: 24),
                BlocBuilder<TransferBloc, TransferState>(
                  builder: (context, state) {
                    final submitting =
                        state.status == TransferStatus.submitting;
                    return SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: submitting
                            ? null
                            : () => context
                                .read<TransferBloc>()
                                .add(const TransferConfirmed()),
                        child: submitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.white,
                                ),
                              )
                            : const Text('Kirim Sekarang'),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final contact = context.select((TransferBloc b) => b.state.selectedContact);

    return Scaffold(
      appBar: AppBar(title: const Text('Nominal Transfer')),
      body: SafeArea(
        child: BlocListener<TransferBloc, TransferState>(
          listenWhen: (prev, curr) => prev.status != curr.status,
          listener: (context, state) {
            if (state.status == TransferStatus.completed) {
              // Close the confirm sheet, then replace this step with the receipt.
              Navigator.of(context).pop();
              context.pushReplacement(AppRouter.transferReceipt);
            } else if (state.status == TransferStatus.failure &&
                state.errorMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.errorMessage!)),
              );
            }
          },
          child: contact == null
              ? const Center(child: Text('Pilih kontak terlebih dahulu.'))
              : ListView(
                  padding: const EdgeInsets.all(AppTheme.defaultMargin),
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primaryLight,
                        child: Text(
                          contact.initial,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      title: Text(contact.name),
                      subtitle: Text(
                          '${contact.bankName} • ${contact.accountNumber}'),
                    ),
                    const SizedBox(height: 16),
                    Text('Nominal',
                        style: textTheme.bodyMedium
                            ?.copyWith(color: AppColors.grey)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      style: textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                      decoration: const InputDecoration(
                        prefixText: 'Rp ',
                        hintText: '0',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _noteController,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Catatan (opsional)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _onContinue,
                      child: const Text('Lanjut'),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool emphasize;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(label,
                style:
                    textTheme.bodyMedium?.copyWith(color: AppColors.grey)),
          ),
          Expanded(
            child: Text(
              value,
              style: emphasize
                  ? textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700)
                  : textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
