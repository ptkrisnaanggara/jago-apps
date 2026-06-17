import '../models/account.dart';
import '../models/shortcut.dart';
import '../../../../core/constants/app_assets.dart';

/// Contract for account data. UI depends on this, not the implementation,
/// so the mock can later be swapped for a real API-backed repository.
abstract class AccountRepository {
  Future<Account> getAccount();
  Future<List<Shortcut>> getShortcuts();
}

/// Temporary in-memory mock. Replace with a network-backed implementation
/// when a backend is available (see PRD §5 "Networking & data").
class MockAccountRepository implements AccountRepository {
  static const _latency = Duration(milliseconds: 600);

  @override
  Future<Account> getAccount() async {
    await Future<void>.delayed(_latency);
    return const Account(
      holderName: 'Shankara Anggara',
      accountNumber: '100 8420 1234',
      balance: 12750000,
    );
  }

  @override
  Future<List<Shortcut>> getShortcuts() async {
    await Future<void>.delayed(_latency);
    return const [
      Shortcut(
        name: 'Kantong Utama',
        imageUrl: AppAssets.wallet,
        amount: 1000000,
      ),
      Shortcut(
        name: 'Kirim & Bayar',
        imageUrl: AppAssets.transaction,
      ),
      Shortcut(
        name: 'Pulsa & Data',
        imageUrl: AppAssets.tasks,
      ),
      Shortcut(
        name: 'Patungan',
        imageUrl: AppAssets.wallet,
      ),
    ];
  }
}
