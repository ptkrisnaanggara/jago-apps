import '../models/pool_models.dart';

abstract class PoolRepository {
  Future<List<MoneyPool>> pools();
  Future<MoneyPool> createPool({required String title, required double target});
  Future<PoolDetail> detail(String id);
  Future<PoolDetail> contribute({
    required String poolId,
    required String name,
    required double amount,
  });
  Future<MoneyPool> close(String id);
}

/// Temporary mock with an in-memory list + per-pool contributions.
class MockPoolRepository implements PoolRepository {
  static const _latency = Duration(milliseconds: 500);

  final List<MoneyPool> _pools = [];
  final Map<String, List<PoolContribution>> _contribs = {};

  @override
  Future<List<MoneyPool>> pools() async {
    await Future<void>.delayed(_latency);
    return List.unmodifiable(_pools);
  }

  @override
  Future<MoneyPool> createPool({
    required String title,
    required double target,
  }) async {
    await Future<void>.delayed(_latency);
    final pool = MoneyPool(
      id: 'pool${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      target: target,
      collected: 0,
      status: PoolStatus.open,
    );
    _pools.insert(0, pool);
    _contribs[pool.id] = [];
    return pool;
  }

  @override
  Future<PoolDetail> detail(String id) async {
    await Future<void>.delayed(_latency);
    return PoolDetail(
      pool: _pools.firstWhere((p) => p.id == id),
      contributions: List.unmodifiable(_contribs[id] ?? const []),
    );
  }

  @override
  Future<PoolDetail> contribute({
    required String poolId,
    required String name,
    required double amount,
  }) async {
    await Future<void>.delayed(_latency);
    final i = _pools.indexWhere((p) => p.id == poolId);
    final pool = _pools[i];
    _pools[i] = MoneyPool(
      id: pool.id,
      title: pool.title,
      target: pool.target,
      collected: pool.collected + amount,
      status: pool.status,
    );
    (_contribs[poolId] ??= []).insert(
      0,
      PoolContribution(
        id: 'c${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        amount: amount,
        createdAt: DateTime.now(),
      ),
    );
    return detail(poolId);
  }

  @override
  Future<MoneyPool> close(String id) async {
    await Future<void>.delayed(_latency);
    final i = _pools.indexWhere((p) => p.id == id);
    final pool = _pools[i];
    _pools[i] = MoneyPool(
      id: pool.id,
      title: pool.title,
      target: pool.target,
      collected: pool.collected,
      status: PoolStatus.closed,
    );
    return _pools[i];
  }
}
