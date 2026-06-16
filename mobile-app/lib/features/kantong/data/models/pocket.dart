import 'package:equatable/equatable.dart';

/// A "Kantong" (savings pocket). [target] is optional for pockets that are
/// not goal-based (e.g. the main pocket).
class Pocket extends Equatable {
  final String id;
  final String name;
  final double balance;
  final double? target;
  final bool isMain;

  const Pocket({
    required this.id,
    required this.name,
    required this.balance,
    this.target,
    this.isMain = false,
  });

  /// Progress toward [target] in the range 0..1, or `null` when no target.
  double? get progress {
    final t = target;
    if (t == null || t <= 0) return null;
    return (balance / t).clamp(0.0, 1.0);
  }

  @override
  List<Object?> get props => [id, name, balance, target, isMain];
}
