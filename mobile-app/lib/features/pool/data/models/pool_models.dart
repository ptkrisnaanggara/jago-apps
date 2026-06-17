import 'package:equatable/equatable.dart';

enum PoolStatus { open, closed }

/// A money pool ("Patungan").
class MoneyPool extends Equatable {
  final String id;
  final String title;
  final double target;
  final double collected;
  final PoolStatus status;

  const MoneyPool({
    required this.id,
    required this.title,
    required this.target,
    required this.collected,
    required this.status,
  });

  bool get isOpen => status == PoolStatus.open;

  /// Progress toward [target] in 0..1.
  double get progress {
    if (target <= 0) return 0;
    return (collected / target).clamp(0.0, 1.0);
  }

  @override
  List<Object?> get props => [id, title, target, collected, status];
}

/// One payment into a pool.
class PoolContribution extends Equatable {
  final String id;
  final String name;
  final double amount;
  final DateTime createdAt;

  const PoolContribution({
    required this.id,
    required this.name,
    required this.amount,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, name, amount, createdAt];
}

/// A pool plus its contributions.
class PoolDetail extends Equatable {
  final MoneyPool pool;
  final List<PoolContribution> contributions;

  const PoolDetail({required this.pool, required this.contributions});

  @override
  List<Object?> get props => [pool, contributions];
}
