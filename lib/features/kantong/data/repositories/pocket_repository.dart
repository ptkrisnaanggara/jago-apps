import '../models/pocket.dart';

abstract class PocketRepository {
  Future<List<Pocket>> getPockets();
}

/// Temporary in-memory mock data source.
class MockPocketRepository implements PocketRepository {
  static const _latency = Duration(milliseconds: 600);

  @override
  Future<List<Pocket>> getPockets() async {
    await Future<void>.delayed(_latency);
    return const [
      Pocket(
        id: 'p0',
        name: 'Kantong Utama',
        balance: 1000000,
        isMain: true,
      ),
      Pocket(id: 'p1', name: 'Dana Darurat', balance: 4500000, target: 10000000),
      Pocket(id: 'p2', name: 'Liburan ke Bali', balance: 2300000, target: 5000000),
      Pocket(id: 'p3', name: 'Gadget Baru', balance: 800000, target: 3000000),
    ];
  }
}
