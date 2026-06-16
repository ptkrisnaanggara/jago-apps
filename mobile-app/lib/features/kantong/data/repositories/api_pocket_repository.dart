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
    return _mapList(list);
  }

  @override
  Future<List<Pocket>> createPocket({
    required String name,
    required PocketType type,
    double? target,
  }) async {
    await _api.post('/pockets', body: {
      'name': name,
      'type': type.name,
      if (target != null) 'target': target.round(),
    });
    return getPockets();
  }

  @override
  Future<List<Pocket>> movePocket({
    required String fromId,
    required String toId,
    required double amount,
  }) async {
    final list = await _api.post('/pockets/move', body: {
      'fromPocketId': fromId,
      'toPocketId': toId,
      'amount': amount.round(),
    }) as List<dynamic>;
    return _mapList(list);
  }

  List<Pocket> _mapList(List<dynamic> list) =>
      list.map((e) => _pocketFromJson(e as Map<String, dynamic>)).toList();

  Pocket _pocketFromJson(Map<String, dynamic> json) {
    final target = json['target'];
    return Pocket(
      id: json['id'] as String,
      name: json['name'] as String,
      type: _typeFromJson(json['type'] as String?),
      balance: (json['balance'] as num).toDouble(),
      target: target == null ? null : (target as num).toDouble(),
      isMain: json['isMain'] as bool? ?? false,
    );
  }

  PocketType _typeFromJson(String? value) => switch (value) {
        'main' => PocketType.main,
        'saving' => PocketType.saving,
        _ => PocketType.spending,
      };
}
