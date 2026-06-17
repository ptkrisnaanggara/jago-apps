part of 'pool_detail_bloc.dart';

sealed class PoolDetailEvent extends Equatable {
  const PoolDetailEvent();

  @override
  List<Object?> get props => [];
}

class PoolDetailStarted extends PoolDetailEvent {
  final String id;

  const PoolDetailStarted(this.id);

  @override
  List<Object?> get props => [id];
}

class PoolContributed extends PoolDetailEvent {
  final String name;
  final double amount;

  const PoolContributed({required this.name, required this.amount});

  @override
  List<Object?> get props => [name, amount];
}

class PoolClosed extends PoolDetailEvent {
  const PoolClosed();
}
