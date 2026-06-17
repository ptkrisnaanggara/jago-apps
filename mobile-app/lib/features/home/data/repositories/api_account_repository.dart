import 'package:jago/core/network/api_client.dart';

import '../../../../core/constants/app_assets.dart';
import '../models/account.dart';
import '../models/shortcut.dart';
import 'account_repository.dart';

/// Backend-backed [AccountRepository]. Shortcuts are a UI-only concept not yet
/// served by the API, so they remain static.
class ApiAccountRepository implements AccountRepository {
  final ApiClient _api;

  ApiAccountRepository(this._api);

  @override
  Future<Account> getAccount() async {
    final json = await _api.get('/account') as Map<String, dynamic>;
    return Account(
      holderName: json['holderName'] as String,
      accountNumber: json['accountNumber'] as String,
      balance: (json['balance'] as num).toDouble(),
    );
  }

  @override
  Future<List<Shortcut>> getShortcuts() async {
    return const [
      Shortcut(name: 'Kantong Utama', imageUrl: AppAssets.wallet),
      Shortcut(name: 'Kirim & Bayar', imageUrl: AppAssets.transaction),
      Shortcut(name: 'Pulsa & Data', imageUrl: AppAssets.tasks),
      Shortcut(name: 'Patungan', imageUrl: AppAssets.wallet),
    ];
  }
}
