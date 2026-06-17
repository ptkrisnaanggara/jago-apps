import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/app_failure.dart';
import '../../data/models/pool_models.dart';
import '../../data/repositories/pool_repository.dart';

part 'pool_detail_event.dart';
part 'pool_detail_state.dart';

/// A single pool's detail (+ contribute / close).
class PoolDetailBloc extends Bloc<PoolDetailEvent, PoolDetailState> {
  final PoolRepository _repository;

  PoolDetailBloc({required PoolRepository repository})
      : _repository = repository,
        super(const PoolDetailState()) {
    on<PoolDetailStarted>(_onStarted);
    on<PoolContributed>(_onContributed);
    on<PoolClosed>(_onClosed);
  }

  Future<void> _onStarted(
    PoolDetailStarted event,
    Emitter<PoolDetailState> emit,
  ) async {
    emit(state.copyWith(status: PoolDetailStatus.loading, id: event.id));
    try {
      final d = await _repository.detail(event.id);
      emit(state.copyWith(status: PoolDetailStatus.success, detail: d));
    } catch (_) {
      emit(state.copyWith(
          status: PoolDetailStatus.failure, failure: AppFailure.poolFailed));
    }
  }

  Future<void> _onContributed(
    PoolContributed event,
    Emitter<PoolDetailState> emit,
  ) async {
    try {
      final d = await _repository.contribute(
        poolId: state.id,
        name: event.name,
        amount: event.amount,
      );
      emit(state.copyWith(status: PoolDetailStatus.success, detail: d));
    } catch (_) {
      emit(state.copyWith(failure: AppFailure.poolFailed));
    }
  }

  Future<void> _onClosed(
    PoolClosed event,
    Emitter<PoolDetailState> emit,
  ) async {
    try {
      await _repository.close(state.id);
      final d = await _repository.detail(state.id);
      emit(state.copyWith(status: PoolDetailStatus.success, detail: d));
    } catch (_) {
      emit(state.copyWith(failure: AppFailure.poolFailed));
    }
  }
}
