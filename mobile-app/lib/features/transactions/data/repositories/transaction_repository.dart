import '../models/transaction.dart';

abstract class TransactionRepository {
  Future<List<TransactionItem>> getTransactions();
}

/// Temporary in-memory mock data source.
class MockTransactionRepository implements TransactionRepository {
  static const _latency = Duration(milliseconds: 600);

  @override
  Future<List<TransactionItem>> getTransactions() async {
    await Future<void>.delayed(_latency);
    final now = DateTime.now();
    return [
      TransactionItem(
        id: 't1',
        title: 'Gaji Bulanan',
        category: 'Pemasukan',
        amount: 9500000,
        type: TransactionType.income,
        date: now.subtract(const Duration(days: 1)),
      ),
      TransactionItem(
        id: 't2',
        title: 'Kopi Kenangan',
        category: 'Makan & Minum',
        amount: 28000,
        type: TransactionType.expense,
        date: now.subtract(const Duration(days: 1, hours: 3)),
      ),
      TransactionItem(
        id: 't3',
        title: 'Transfer ke Budi',
        category: 'Kirim & Bayar',
        amount: 150000,
        type: TransactionType.expense,
        date: now.subtract(const Duration(days: 2)),
      ),
      TransactionItem(
        id: 't4',
        title: 'Tagihan Listrik PLN',
        category: 'Tagihan',
        amount: 320000,
        type: TransactionType.expense,
        date: now.subtract(const Duration(days: 3)),
      ),
      TransactionItem(
        id: 't5',
        title: 'Cashback Belanja',
        category: 'Pemasukan',
        amount: 45000,
        type: TransactionType.income,
        date: now.subtract(const Duration(days: 4)),
      ),
    ];
  }
}
