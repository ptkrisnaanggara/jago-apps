import 'package:jago/core/network/api_client.dart';

import '../models/contact.dart';
import '../models/transfer_result.dart';
import 'transfer_repository.dart';

/// Backend-backed [TransferRepository]. The backend has no contacts endpoint
/// yet, so the picker list stays static; the transfer itself hits the API.
class ApiTransferRepository implements TransferRepository {
  final ApiClient _api;

  ApiTransferRepository(this._api);

  @override
  Future<List<Contact>> getContacts() async {
    return const [
      Contact(id: 'c1', name: 'Budi Santoso', bankName: 'Bank Jago', accountNumber: '100 8420 5566'),
      Contact(id: 'c2', name: 'Siti Rahmawati', bankName: 'BCA', accountNumber: '012 3456 7890'),
      Contact(id: 'c3', name: 'Andi Pratama', bankName: 'Mandiri', accountNumber: '137 0099 8877'),
      Contact(id: 'c4', name: 'Dewi Lestari', bankName: 'BNI', accountNumber: '088 1212 3434'),
      Contact(id: 'c5', name: 'Eko Wijaya', bankName: 'Bank Jago', accountNumber: '100 7711 2299'),
    ];
  }

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
