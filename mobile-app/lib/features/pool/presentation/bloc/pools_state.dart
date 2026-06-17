part of 'pools_bloc.dart';

enum PoolsStatus { initial, loading, success, failure }

class PoolsState extends Equatable {
  final PoolsStatus status;
  final List<MoneyPool> pools;
  final AppFailure? failure;

  const PoolsState({
    this.status = PoolsStatus.initial,
    this.pools = const [],
    this.failure,
  });

  PoolsState copyWith({
    PoolsStatus? status,
    List<MoneyPool>? pools,
    AppFailure? failure,
  }) {
    return PoolsState(
      status: status ?? this.status,
      pools: pools ?? this.pools,
      failure: failure,
    );
  }

  @override
  List<Object?> get props => [status, pools, failure];
}
