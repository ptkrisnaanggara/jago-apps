import 'package:equatable/equatable.dart';

/// Kind of pocket, mirroring Bank Jago's Kantong types.
enum PocketType { main, spending, saving }

/// A "Kantong" (pocket). [target] is optional for pockets that are not
/// goal-based (e.g. the main pocket).
class Pocket extends Equatable {
  final String id;
  final String name;
  final PocketType type;
  final double balance;
  final double? target;
  final bool isMain;

  /// Saving lock: while locked, money cannot be moved out.
  final bool locked;
  final DateTime? lockUntil;

  /// Autosave: recurring top-up from the main pocket (0 = off).
  final double autosaveAmount;
  final String autosaveFrequency; // none | daily | weekly | monthly

  /// Shared (Kantong Bersama) state + the current user's role.
  final bool shared;
  final String role; // owner | member | ''

  const Pocket({
    required this.id,
    required this.name,
    this.type = PocketType.spending,
    required this.balance,
    this.target,
    this.isMain = false,
    this.locked = false,
    this.lockUntil,
    this.autosaveAmount = 0,
    this.autosaveFrequency = 'none',
    this.shared = false,
    this.role = '',
  });

  bool get isMember => role == 'member';
  bool get isOwner => role == 'owner';

  /// Progress toward [target] in the range 0..1, or `null` when no target.
  double? get progress {
    final t = target;
    if (t == null || t <= 0) return null;
    return (balance / t).clamp(0.0, 1.0);
  }

  bool get hasAutosave => autosaveAmount > 0;

  Pocket copyWith({
    double? balance,
    bool? locked,
    DateTime? lockUntil,
    bool clearLockUntil = false,
    double? autosaveAmount,
    String? autosaveFrequency,
    bool? shared,
  }) {
    return Pocket(
      id: id,
      name: name,
      type: type,
      balance: balance ?? this.balance,
      target: target,
      isMain: isMain,
      locked: locked ?? this.locked,
      lockUntil: clearLockUntil ? null : (lockUntil ?? this.lockUntil),
      autosaveAmount: autosaveAmount ?? this.autosaveAmount,
      autosaveFrequency: autosaveFrequency ?? this.autosaveFrequency,
      shared: shared ?? this.shared,
      role: role,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        type,
        balance,
        target,
        isMain,
        locked,
        lockUntil,
        autosaveAmount,
        autosaveFrequency,
        shared,
        role,
      ];
}

/// A member of a shared pocket.
class PocketMember extends Equatable {
  final String userId;
  final String name;
  final String role; // owner | member

  const PocketMember({
    required this.userId,
    required this.name,
    required this.role,
  });

  @override
  List<Object?> get props => [userId, name, role];
}
