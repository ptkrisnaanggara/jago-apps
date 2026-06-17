import 'package:jago/core/network/api_client.dart';

import '../models/contact.dart';
import '../models/transfer_result.dart';
import 'transfer_repository.dart';

/// Backend-backed [TransferRepository].
class ApiTransferRepository implements TransferRepository {
  final ApiClient _api;

  ApiTransferRepository(this._api);

  @override
  Future<List<Contact>> getContacts() async {
    final list = await _api.get('/contacts') as List<dynamic>;
    return list
        .map((e) => _contactFromJson(e as Map<String, dynamic>))
        .toList();
  }

  Contact _contactFromJson(Map<String, dynamic> json) => Contact(
        id: json['id'] as String,
        name: json['name'] as String,
        bankName: json['bankName'] as String,
        accountNumber: json['accountNumber'] as String,
      );

  @override
  Future<TransferResult> submitTransfer({
    required Contact contact,
    required double amount,
    required String note,
  }) async {
    final json = await _api.post('/transfers', body: {
      'recipientName': contact.name,
      'recipientBank': contact.bankName,
      'recipientAccount': contact.accountNumber,
      'amount': amount.round(),
      'note': note,
    }) as Map<String, dynamic>;

    return TransferResult(
      referenceId: json['referenceId'] as String,
      contact: contact,
      amount: (json['amount'] as num).toDouble(),
      note: json['note'] as String? ?? note,
      timestamp: DateTime.parse(json['createdAt'] as String),
    );
  }
}
