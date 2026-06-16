import '../models/bill.dart';

/// Contract for bills / payment plans. UI/BLoC depend on this, not the mock.
abstract class BillsRepository {
  Future<List<Bill>> getBills();

  /// Marks a bill paid and returns the updated list.
  Future<List<Bill>> payBill(String id);

  /// Schedules a new bill / payment plan and returns the updated list.
  Future<List<Bill>> scheduleBill(Bill bill);
}

/// Temporary mock. Holds a mutable in-memory list so pay/schedule mutations
/// persist for the session (a real impl would call an API).
class MockBillsRepository implements BillsRepository {
  static const _latency = Duration(milliseconds: 600);

  final List<Bill> _bills = _seed();

  static List<Bill> _seed() {
    final now = DateTime.now();
    DateTime inDays(int d) => DateTime(now.year, now.month, now.day + d);
    return [
      Bill(
        id: 'b1',
        biller: 'PLN Pascabayar',
        category: 'Listrik',
        amount: 320000,
        dueDate: inDays(3),
        recurrence: BillRecurrence.monthly,
      ),
      Bill(
        id: 'b2',
        biller: 'IndiHome',
        category: 'Internet',
        amount: 410000,
        dueDate: inDays(8),
        recurrence: BillRecurrence.monthly,
      ),
      Bill(
        id: 'b3',
        biller: 'BPJS Kesehatan',
        category: 'Asuransi',
        amount: 150000,
        dueDate: inDays(-2),
        recurrence: BillRecurrence.monthly,
      ),
      Bill(
        id: 'b4',
        biller: 'PDAM',
        category: 'Air',
        amount: 95000,
        dueDate: inDays(-10),
        isPaid: true,
        recurrence: BillRecurrence.monthly,
      ),
    ];
  }

  @override
  Future<List<Bill>> getBills() async {
    await Future<void>.delayed(_latency);
    return List.unmodifiable(_bills);
  }

  @override
  Future<List<Bill>> payBill(String id) async {
    await Future<void>.delayed(_latency);
    final i = _bills.indexWhere((b) => b.id == id);
    if (i != -1) _bills[i] = _bills[i].copyWith(isPaid: true);
    return List.unmodifiable(_bills);
  }

  @override
  Future<List<Bill>> scheduleBill(Bill bill) async {
    await Future<void>.delayed(_latency);
    _bills.add(bill);
    return List.unmodifiable(_bills);
  }
}
