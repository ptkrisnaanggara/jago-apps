import 'package:jago/core/network/api_client.dart';

import '../models/pocket.dart';
import 'pocket_repository.dart';

/// Backend-backed [PocketRepository].
class ApiPocketRepository implements PocketRepository {
  final ApiClient _api;

  ApiPocketRepository(this._api);

  @override
  Future<List<Pocket>> getPockets() async {
    final list = await _api.get('/pockets') as List<dynamic>;
    return list
        .map((e) => _pocketFromJson(e as Map<String, dynamic>))
        .toList();
  }

  Pocket _pocketFromJson(Map<String, dynamic> json) {
    final target = json['target'];
    return Pocket(
      id: json['id'] as String,
      name: json['name'] as String,
      balance: (json['balance'] as num).toDouble(),
      target: target == null ? null : (target as num).toDouble(),
      isMain: json['isMain'] as bool? ?? false,
    );
  }
}
