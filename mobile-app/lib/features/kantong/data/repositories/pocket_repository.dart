import '../models/pocket.dart';

abstract class PocketRepository {
  Future<List<Pocket>> getPockets();

  /// Creates a new (empty) pocket and returns the updated list.
  Future<List<Pocket>> createPocket({
    required String name,
    required PocketType type,
    double? target,
  });

  /// Moves money between two pockets and returns the updated list.
  Future<List<Pocket>> movePocket({
    required String fromId,
    required String toId,
    required double amount,
  });
}

/// Temporary mock. Holds a mutable in-memory list so create/move persist for
/// the session.
class MockPocketRepository implements PocketRepository {
  static const _latency = Duration(milliseconds: 600);

  final List<Pocket> _pockets = [
    const Pocket(
        id: 'p0',
        name: 'Kantong Utama',
        type: PocketType.main,
        balance: 1000000,
        isMain: true),
    const Pocket(
        id: 'p1',
        name: 'Dana Darurat',
        type: PocketType.saving,
        balance: 4500000,
        target: 10000000),
    const Pocket(
        id: 'p2',
        name: 'Liburan ke Bali',
        type: PocketType.saving,
        balance: 2300000,
        target: 5000000),
  ];

  @override
  Future<List<Pocket>> getPockets() async {
    await Future<void>.delayed(_latency);
    return List.unmodifiable(_pockets);
  }

  @override
  Future<List<Pocket>> createPocket({
    required String name,
    required PocketType type,
    double? target,
  }) async {
    await Future<void>.delayed(_latency);
    _pockets.add(Pocket(
      id: 'p${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      type: type,
      balance: 0,
      target: target,
    ));
    return List.unmodifiable(_pockets);
  }

  @override
  Future<List<Pocket>> movePocket({
    required String fromId,
    required String toId,
    required double amount,
  }) async {
    await Future<void>.delayed(_latency);
    final from = _pockets.indexWhere((p) => p.id == fromId);
    final to = _pockets.indexWhere((p) => p.id == toId);
    if (from != -1 && to != -1 && _pockets[from].balance >= amount) {
      _pockets[from] =
          _copyBalance(_pockets[from], _pockets[from].balance - amount);
      _pockets[to] = _copyBalance(_pockets[to], _pockets[to].balance + amount);
    }
    return List.unmodifiable(_pockets);
  }

  Pocket _copyBalance(Pocket p, double balance) => Pocket(
        id: p.id,
        name: p.name,
        type: p.type,
        balance: balance,
        target: p.target,
        isMain: p.isMain,
      );
}
