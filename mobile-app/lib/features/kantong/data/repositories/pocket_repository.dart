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

  Future<List<Pocket>> setLocked(String id, {required bool locked});

  Future<List<Pocket>> setAutosave(
    String id, {
    required double amount,
    required String frequency,
  });

  Future<List<Pocket>> runAutosave(String id);

  /// Shares a pocket with another user (by phone); returns the updated list.
  Future<List<Pocket>> sharePocket(String id, {required String phone});

  /// Deposits from the caller's main pocket into a (shared) pocket.
  Future<List<Pocket>> deposit(String id, {required double amount});

  Future<List<PocketMember>> members(String id);
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
    if (from != -1 && to != -1 && !_pockets[from].locked &&
        _pockets[from].balance >= amount) {
      _pockets[from] =
          _pockets[from].copyWith(balance: _pockets[from].balance - amount);
      _pockets[to] = _pockets[to].copyWith(balance: _pockets[to].balance + amount);
    }
    return List.unmodifiable(_pockets);
  }

  @override
  Future<List<Pocket>> setLocked(String id, {required bool locked}) async {
    await Future<void>.delayed(_latency);
    _update(id, (p) => p.copyWith(locked: locked, clearLockUntil: !locked));
    return List.unmodifiable(_pockets);
  }

  @override
  Future<List<Pocket>> setAutosave(
    String id, {
    required double amount,
    required String frequency,
  }) async {
    await Future<void>.delayed(_latency);
    final off = amount <= 0;
    _update(
        id,
        (p) => p.copyWith(
            autosaveAmount: off ? 0 : amount,
            autosaveFrequency: off ? 'none' : frequency));
    return List.unmodifiable(_pockets);
  }

  @override
  Future<List<Pocket>> runAutosave(String id) async {
    await Future<void>.delayed(_latency);
    final i = _pockets.indexWhere((p) => p.id == id);
    final main = _pockets.indexWhere((p) => p.isMain);
    if (i != -1 && main != -1 && _pockets[i].autosaveAmount > 0) {
      final amt = _pockets[i].autosaveAmount;
      _pockets[main] = _pockets[main].copyWith(balance: _pockets[main].balance - amt);
      _pockets[i] = _pockets[i].copyWith(balance: _pockets[i].balance + amt);
    }
    return List.unmodifiable(_pockets);
  }

  final Map<String, List<PocketMember>> _members = {};

  @override
  Future<List<Pocket>> sharePocket(String id, {required String phone}) async {
    await Future<void>.delayed(_latency);
    _update(id, (p) => p.copyWith(shared: true));
    final list = _members.putIfAbsent(id, () => [
          const PocketMember(userId: 'me', name: 'Saya', role: 'owner'),
        ]);
    if (!list.any((m) => m.name == '+62 $phone')) {
      list.add(PocketMember(userId: phone, name: '+62 $phone', role: 'member'));
    }
    return List.unmodifiable(_pockets);
  }

  @override
  Future<List<Pocket>> deposit(String id, {required double amount}) async {
    await Future<void>.delayed(_latency);
    final i = _pockets.indexWhere((p) => p.id == id);
    final main = _pockets.indexWhere((p) => p.isMain);
    if (i != -1 && main != -1 && _pockets[main].balance >= amount) {
      _pockets[main] =
          _pockets[main].copyWith(balance: _pockets[main].balance - amount);
      _pockets[i] = _pockets[i].copyWith(balance: _pockets[i].balance + amount);
    }
    return List.unmodifiable(_pockets);
  }

  @override
  Future<List<PocketMember>> members(String id) async {
    await Future<void>.delayed(_latency);
    return _members[id] ??
        const [PocketMember(userId: 'me', name: 'Saya', role: 'owner')];
  }

  void _update(String id, Pocket Function(Pocket) f) {
    final i = _pockets.indexWhere((p) => p.id == id);
    if (i != -1) _pockets[i] = f(_pockets[i]);
  }
}
