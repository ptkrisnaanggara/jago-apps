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

  @override
  Future<List<Pocket>> setLocked(String id, {required bool locked}) async {
    final list = await _api.post('/pockets/$id/${locked ? 'lock' : 'unlock'}')
        as List<dynamic>;
    return _mapList(list);
  }

  @override
  Future<List<Pocket>> setAutosave(
    String id, {
    required double amount,
    required String frequency,
  }) async {
    final list = await _api.post('/pockets/$id/autosave',
        body: {'amount': amount.round(), 'frequency': frequency}) as List<dynamic>;
    return _mapList(list);
  }

  @override
  Future<List<Pocket>> runAutosave(String id) async {
    final list = await _api.post('/pockets/$id/autosave/run') as List<dynamic>;
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
      locked: json['locked'] as bool? ?? false,
      lockUntil: json['lockUntil'] == null
          ? null
          : DateTime.tryParse(json['lockUntil'] as String),
      autosaveAmount: (json['autosaveAmount'] as num?)?.toDouble() ?? 0,
      autosaveFrequency: json['autosaveFrequency'] as String? ?? 'none',
    );
  }

  PocketType _typeFromJson(String? value) => switch (value) {
        'main' => PocketType.main,
        'saving' => PocketType.saving,
        _ => PocketType.spending,
      };
}
