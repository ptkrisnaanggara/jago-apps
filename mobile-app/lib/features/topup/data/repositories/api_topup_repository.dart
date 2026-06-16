import 'package:jago/core/network/api_client.dart';

import '../models/topup_models.dart';
import 'topup_repository.dart';

/// Backend-backed [TopupRepository].
class ApiTopupRepository implements TopupRepository {
  final ApiClient _api;

  ApiTopupRepository(this._api);

  @override
  Future<List<TopupProduct>> products() async {
    final list = await _api.get('/topup/products') as List<dynamic>;
    return list.map((e) {
      final json = e as Map<String, dynamic>;
      return TopupProduct(
        id: json['id'] as String,
        type: json['type'] as String,
        name: json['name'] as String,
        amount: (json['amount'] as num).toDouble(),
      );
    }).toList();
  }

  @override
  Future<TopupReceipt> purchase({
    required String productId,
    required String phone,
    String? pocketId,
  }) async {
    final json = await _api.post('/topup', body: {
      'productId': productId,
      'phone': phone,
      if (pocketId != null) 'pocketId': pocketId,
    }) as Map<String, dynamic>;

    return TopupReceipt(
      productName: json['productName'] as String,
      type: json['type'] as String,
      phone: json['phone'] as String,
      amount: (json['amount'] as num).toDouble(),
      pocketName: json['pocketName'] as String? ?? '',
      referenceId: json['referenceId'] as String,
      paidAt: DateTime.parse(json['paidAt'] as String),
    );
  }
}
