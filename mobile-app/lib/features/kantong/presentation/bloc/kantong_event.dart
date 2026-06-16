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
