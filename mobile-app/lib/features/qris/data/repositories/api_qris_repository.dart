import 'package:jago/core/network/api_client.dart';

import '../models/qris_models.dart';
import 'qris_repository.dart';

/// Backend-backed [QrisRepository].
class ApiQrisRepository implements QrisRepository {
  final ApiClient _api;

  ApiQrisRepository(this._api);

  @override
  Future<QrisInfo> parse(String payload) async {
    final json = await _api.post('/qris/parse', body: {'payload': payload})
        as Map<String, dynamic>;
    return QrisInfo(
      merchantName: json['merchantName'] as String,
      merchantCity: json['merchantCity'] as String? ?? '',
      amount: (json['amount'] as num).toDouble(),
      dynamic_: json['dynamic'] as bool? ?? false,
    );
  }

  @override
  Future<QrisReceipt> pay({
    required String payload,
    String? pocketId,
    double? amount,
  }) async {
    final json = await _api.post('/qris/pay', body: {
      'payload': payload,
      if (pocketId != null) 'pocketId': pocketId,
      if (amount != null) 'amount': amount.round(),
    }) as Map<String, dynamic>;

    return QrisReceipt(
      merchantName: json['merchantName'] as String,
      merchantCity: json['merchantCity'] as String? ?? '',
      amount: (json['amount'] as num).toDouble(),
      pocketName: json['pocketName'] as String? ?? '',
      referenceId: json['referenceId'] as String,
      paidAt: DateTime.parse(json['paidAt'] as String),
    );
  }
}
