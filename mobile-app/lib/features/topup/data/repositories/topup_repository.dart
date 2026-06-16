import '../models/topup_models.dart';

abstract class TopupRepository {
  Future<List<TopupProduct>> products();

  Future<TopupReceipt> purchase({
    required String productId,
    required String phone,
    String? pocketId,
  });
}

/// Temporary mock mirroring the backend catalog.
class MockTopupRepository implements TopupRepository {
  static const _latency = Duration(milliseconds: 500);

  static const _catalog = [
    TopupProduct(id: 'pulsa-5', type: 'pulsa', name: 'Pulsa 5.000', amount: 5000),
    TopupProduct(id: 'pulsa-10', type: 'pulsa', name: 'Pulsa 10.000', amount: 10000),
    TopupProduct(id: 'pulsa-25', type: 'pulsa', name: 'Pulsa 25.000', amount: 25000),
    TopupProduct(id: 'pulsa-50', type: 'pulsa', name: 'Pulsa 50.000', amount: 50000),
    TopupProduct(id: 'pulsa-100', type: 'pulsa', name: 'Pulsa 100.000', amount: 100000),
    TopupProduct(id: 'data-s', type: 'data', name: 'Paket Data 3GB', amount: 25000),
    TopupProduct(id: 'data-m', type: 'data', name: 'Paket Data 8GB', amount: 50000),
    TopupProduct(id: 'data-l', type: 'data', name: 'Paket Data 20GB', amount: 95000),
  ];

  @override
  Future<List<TopupProduct>> products() async {
    await Future<void>.delayed(_latency);
    return _catalog;
  }

  @override
  Future<TopupReceipt> purchase({
    required String productId,
    required String phone,
    String? pocketId,
  }) async {
    await Future<void>.delayed(_latency);
    final p = _catalog.firstWhere((e) => e.id == productId);
    return TopupReceipt(
      productName: p.name,
      type: p.type,
      phone: phone,
      amount: p.amount,
      pocketName: 'Kantong Utama',
      referenceId: 'TP${DateTime.now().millisecondsSinceEpoch}',
      paidAt: DateTime.now(),
    );
  }
}
