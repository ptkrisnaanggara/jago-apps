part of 'pool_detail_bloc.dart';

enum PoolDetailStatus { initial, loading, success, failure }

class PoolDetailState extends Equatable {
  final PoolDetailStatus status;
  final String id;
  final PoolDetail? detail;
  final AppFailure? failure;

  const PoolDetailState({
    this.status = PoolDetailStatus.initial,
    this.id = '',
    this.detail,
    this.failure,
  });

  PoolDetailState copyWith({
    PoolDetailStatus? status,
    String? id,
    PoolDetail? detail,
    AppFailure? failure,
  }) {
    return PoolDetailState(
      status: status ?? this.status,
      id: id ?? this.id,
      detail: detail ?? this.detail,
      failure: failure,
    );
  }

  @override
  List<Object?> get props => [status, id, detail, failure];
}
