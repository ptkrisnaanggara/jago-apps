part of 'kantong_bloc.dart';

sealed class KantongEvent extends Equatable {
  const KantongEvent();

  @override
  List<Object?> get props => [];
}

class KantongStarted extends KantongEvent {
  const KantongStarted();
}

class KantongPocketCreated extends KantongEvent {
  final String name;
  final PocketType type;
  final double? target;

  const KantongPocketCreated({
    required this.name,
    required this.type,
    this.target,
  });

  @override
  List<Object?> get props => [name, type, target];
}

class KantongMoneyMoved extends KantongEvent {
  final String fromId;
  final String toId;
  final double amount;

  const KantongMoneyMoved({
    required this.fromId,
    required this.toId,
    required this.amount,
  });

  @override
  List<Object?> get props => [fromId, toId, amount];
}

class KantongLockToggled extends KantongEvent {
  final String id;
  final bool locked;

  const KantongLockToggled({required this.id, required this.locked});

  @override
  List<Object?> get props => [id, locked];
}

class KantongAutosaveSet extends KantongEvent {
  final String id;
  final double amount;
  final String frequency;

  const KantongAutosaveSet({
    required this.id,
    required this.amount,
    required this.frequency,
  });

  @override
  List<Object?> get props => [id, amount, frequency];
}

class KantongAutosaveRun extends KantongEvent {
  final String id;

  const KantongAutosaveRun(this.id);

  @override
  List<Object?> get props => [id];
}

class KantongPocketShared extends KantongEvent {
  final String id;
  final String phone;

  const KantongPocketShared({required this.id, required this.phone});

  @override
  List<Object?> get props => [id, phone];
}

class KantongDeposited extends KantongEvent {
  final String id;
  final double amount;

  const KantongDeposited({required this.id, required this.amount});

  @override
  List<Object?> get props => [id, amount];
}
