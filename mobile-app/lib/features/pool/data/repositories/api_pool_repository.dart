import 'package:jago/core/network/api_client.dart';

import '../models/pool_models.dart';
import 'pool_repository.dart';

/// Backend-backed [PoolRepository].
class ApiPoolRepository implements PoolRepository {
  final ApiClient _api;

  ApiPoolRepository(this._api);

  @override
  Future<List<MoneyPool>> pools() async {
    final list = await _api.get('/pools') as List<dynamic>;
    return list.map((e) => _poolFromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<MoneyPool> createPool({
    required String title,
    required double target,
  }) async {
    final json = await _api.post('/pools',
        body: {'title': title, 'target': target.round()}) as Map<String, dynamic>;
    return _poolFromJson(json);
  }

  @override
  Future<PoolDetail> detail(String id) async {
    final json = await _api.get('/pools/$id') as Map<String, dynamic>;
    return _detailFromJson(json);
  }

  @override
  Future<PoolDetail> contribute({
    required String poolId,
    required String name,
    required double amount,
  }) async {
    final json = await _api.post('/pools/$poolId/contribute',
            body: {'name': name, 'amount': amount.round()})
        as Map<String, dynamic>;
    return _detailFromJson(json);
  }

  @override
  Future<MoneyPool> close(String id) async {
    final json =
        await _api.post('/pools/$id/close') as Map<String, dynamic>;
    return _poolFromJson(json);
  }

  PoolDetail _detailFromJson(Map<String, dynamic> json) {
    final contribs = (json['contributions'] as List<dynamic>? ?? [])
        .map((e) => _contribFromJson(e as Map<String, dynamic>))
        .toList();
    return PoolDetail(
      pool: _poolFromJson(json['pool'] as Map<String, dynamic>),
      contributions: contribs,
    );
  }

  MoneyPool _poolFromJson(Map<String, dynamic> json) => MoneyPool(
        id: json['id'] as String,
        title: json['title'] as String,
        target: (json['target'] as num).toDouble(),
        collected: (json['collected'] as num).toDouble(),
        status: json['status'] == 'closed' ? PoolStatus.closed : PoolStatus.open,
      );

  PoolContribution _contribFromJson(Map<String, dynamic> json) =>
      PoolContribution(
        id: json['id'] as String,
        name: json['name'] as String,
        amount: (json['amount'] as num).toDouble(),
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
