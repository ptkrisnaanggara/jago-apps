import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/app_failure.dart';
import '../../data/models/pool_models.dart';
import '../../data/repositories/pool_repository.dart';

part 'pools_event.dart';
part 'pools_state.dart';

/// The money-pool list (+ create).
class PoolsBloc extends Bloc<PoolsEvent, PoolsState> {
  final PoolRepository _repository;

  PoolsBloc({required PoolRepository repository})
      : _repository = repository,
        super(const PoolsState()) {
    on<PoolsStarted>(_onStarted);
    on<PoolCreated>(_onCreated);
  }

  Future<void> _onStarted(PoolsStarted event, Emitter<PoolsState> emit) async {
    emit(state.copyWith(status: PoolsStatus.loading));
    try {
      emit(state.copyWith(
          status: PoolsStatus.success, pools: await _repository.pools()));
    } catch (_) {
      emit(state.copyWith(
          status: PoolsStatus.failure, failure: AppFailure.poolFailed));
    }
  }

  Future<void> _onCreated(PoolCreated event, Emitter<PoolsState> emit) async {
    try {
      await _repository.createPool(title: event.title, target: event.target);
      emit(state.copyWith(
          status: PoolsStatus.success, pools: await _repository.pools()));
    } catch (_) {
      emit(state.copyWith(failure: AppFailure.poolFailed));
    }
  }
}
