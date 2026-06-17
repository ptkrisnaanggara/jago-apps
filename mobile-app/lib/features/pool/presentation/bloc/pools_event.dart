part of 'pools_bloc.dart';

sealed class PoolsEvent extends Equatable {
  const PoolsEvent();

  @override
  List<Object?> get props => [];
}

class PoolsStarted extends PoolsEvent {
  const PoolsStarted();
}

class PoolCreated extends PoolsEvent {
  final String title;
  final double target;

  const PoolCreated({required this.title, required this.target});

  @override
  List<Object?> get props => [title, target];
}
