import 'package:jago/core/network/api_client.dart';

import '../models/bill.dart';
import 'bills_repository.dart';

/// Backend-backed [BillsRepository]. Pay/schedule mutate then re-fetch the list
/// to match the interface (which returns the updated list).
class ApiBillsRepository implements BillsRepository {
  final ApiClient _api;

  ApiBillsRepository(this._api);

  @override
  Future<List<Bill>> getBills() async {
    final list = await _api.get('/bills') as List<dynamic>;
    return list.map((e) => _billFromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<Bill>> payBill(String id) async {
    await _api.post('/bills/$id/pay');
    return getBills();
  }

  @override
  Future<List<Bill>> scheduleBill(Bill bill) async {
    await _api.post('/bills', body: {
      'biller': bill.biller,
      'category': bill.category,
      'amount': bill.amount.round(),
      'dueDate': bill.dueDate.toUtc().toIso8601String(),
      'recurrence': bill.recurrence.name,
    });
    return getBills();
  }

  Bill _billFromJson(Map<String, dynamic> json) {
    return Bill(
      id: json['id'] as String,
      biller: json['biller'] as String,
      category: json['category'] as String,
      amount: (json['amount'] as num).toDouble(),
      dueDate: DateTime.parse(json['dueDate'] as String),
      isPaid: json['isPaid'] as bool? ?? false,
      recurrence: _recurrenceFromJson(json['recurrence'] as String?),
    );
  }

  BillRecurrence _recurrenceFromJson(String? value) {
    return switch (value) {
      'weekly' => BillRecurrence.weekly,
      'monthly' => BillRecurrence.monthly,
      _ => BillRecurrence.none,
    };
  }
}
