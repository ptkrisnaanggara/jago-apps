import '../models/qris_models.dart';

abstract class QrisRepository {
  Future<QrisInfo> parse(String payload);

  Future<QrisReceipt> pay({
    required String payload,
    String? pocketId,
    double? amount,
  });
}

/// Temporary mock. Returns a fixed merchant; the amount is whatever the caller
/// enters (dynamic-style), so the flow is exercisable without the backend.
class MockQrisRepository implements QrisRepository {
  static const _latency = Duration(milliseconds: 500);

  @override
  Future<QrisInfo> parse(String payload) async {
    await Future<void>.delayed(_latency);
    return const QrisInfo(
      merchantName: 'Toko Demo QRIS',
      merchantCity: 'Jakarta',
      amount: 0,
      dynamic_: false,
    );
  }

  @override
  Future<QrisReceipt> pay({
    required String payload,
    String? pocketId,
    double? amount,
  }) async {
    await Future<void>.delayed(_latency);
    return QrisReceipt(
      merchantName: 'Toko Demo QRIS',
      merchantCity: 'Jakarta',
      amount: amount ?? 0,
      pocketName: 'Kantong Utama',
      referenceId: 'QR${DateTime.now().millisecondsSinceEpoch}',
      paidAt: DateTime.now(),
    );
  }
}
