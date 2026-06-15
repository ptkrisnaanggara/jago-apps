import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/bill.dart';
import '../bloc/bills_bloc.dart';

/// Schedule a new bill / payment plan.
class CreatePaymentPlanPage extends StatefulWidget {
  const CreatePaymentPlanPage({super.key});

  @override
  State<CreatePaymentPlanPage> createState() => _CreatePaymentPlanPageState();
}

class _CreatePaymentPlanPageState extends State<CreatePaymentPlanPage> {
  static const _categories = [
    'Listrik',
    'Internet',
    'Air',
    'Asuransi',
    'Telepon',
    'Lainnya',
  ];

  final _formKey = GlobalKey<FormState>();
  final _billerController = TextEditingController();
  final _amountController = TextEditingController();

  String _category = _categories.first;
  BillRecurrence _recurrence = BillRecurrence.monthly;
  DateTime _dueDate = DateTime.now().add(const Duration(days: 7));

  @override
  void dispose() {
    _billerController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 365 * 2)),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final bill = Bill(
      id: 'b${DateTime.now().millisecondsSinceEpoch}',
      biller: _billerController.text.trim(),
      category: _category,
      amount: double.parse(_amountController.text.trim()),
      dueDate: _dueDate,
      recurrence: _recurrence,
    );
    context.read<BillsBloc>().add(BillScheduled(bill));
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat('d MMM yyyy', 'id_ID').format(_dueDate);
    return Scaffold(
      appBar: AppBar(title: const Text('Rencana Pembayaran Baru')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(AppTheme.defaultMargin),
            children: [
              TextFormField(
                controller: _billerController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Nama tagihan / penyedia',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Nama tagihan wajib diisi'
                    : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _category,
                decoration: const InputDecoration(
                  labelText: 'Kategori',
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (final c in _categories)
                    DropdownMenuItem(value: c, child: Text(c)),
                ],
                onChanged: (v) => setState(() => _category = v ?? _category),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Nominal',
                  prefixText: 'Rp ',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  final amount = double.tryParse(v?.trim() ?? '') ?? 0;
                  return amount <= 0 ? 'Masukkan nominal yang valid' : null;
                },
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(AppTheme.defaultRadius),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Jatuh tempo',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today_rounded, size: 18),
                  ),
                  child: Text(dateLabel),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<BillRecurrence>(
                value: _recurrence,
                decoration: const InputDecoration(
                  labelText: 'Pengulangan',
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (final r in BillRecurrence.values)
                    DropdownMenuItem(value: r, child: Text(r.label)),
                ],
                onChanged: (v) =>
                    setState(() => _recurrence = v ?? _recurrence),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                  ),
                  child: const Text('Simpan Rencana'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
