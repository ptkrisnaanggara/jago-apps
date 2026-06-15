import '../models/contact.dart';
import '../models/transfer_result.dart';

/// Contract for the Transfer & Pay flow. The UI/BLoC depend on this, not the
/// mock, so a real API-backed implementation can be swapped in later.
abstract class TransferRepository {
  Future<List<Contact>> getContacts();

  Future<TransferResult> submitTransfer({
    required Contact contact,
    required double amount,
    required String note,
  });
}

/// Temporary in-memory mock.
class MockTransferRepository implements TransferRepository {
  static const _latency = Duration(milliseconds: 600);

  @override
  Future<List<Contact>> getContacts() async {
    await Future<void>.delayed(_latency);
    return const [
      Contact(
        id: 'c1',
        name: 'Budi Santoso',
        bankName: 'Bank Jago',
        accountNumber: '100 8420 5566',
      ),
      Contact(
        id: 'c2',
        name: 'Siti Rahmawati',
        bankName: 'BCA',
        accountNumber: '012 3456 7890',
      ),
      Contact(
        id: 'c3',
        name: 'Andi Pratama',
        bankName: 'Mandiri',
        accountNumber: '137 0099 8877',
      ),
      Contact(
        id: 'c4',
        name: 'Dewi Lestari',
        bankName: 'BNI',
        accountNumber: '088 1212 3434',
      ),
      Contact(
        id: 'c5',
        name: 'Eko Wijaya',
        bankName: 'Bank Jago',
        accountNumber: '100 7711 2299',
      ),
    ];
  }

  @override
  Future<TransferResult> submitTransfer({
    required Contact contact,
    required double amount,
    required String note,
  }) async {
    await Future<void>.delayed(_latency);
    final now = DateTime.now();
    return TransferResult(
      referenceId: 'JG${now.millisecondsSinceEpoch}',
      contact: contact,
      amount: amount,
      note: note,
      timestamp: now,
    );
  }
}
