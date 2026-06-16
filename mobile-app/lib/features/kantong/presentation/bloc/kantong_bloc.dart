import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/app_failure.dart';
import '../../data/models/pocket.dart';
import '../../data/repositories/pocket_repository.dart';

part 'kantong_event.dart';
part 'kantong_state.dart';

class KantongBloc extends Bloc<KantongEvent, KantongState> {
  final PocketRepository _repository;

  KantongBloc({required PocketRepository repository})
      : _repository = repository,
        super(const KantongState()) {
    on<KantongStarted>(_onStarted);
  }

  Future<void> _onStarted(
    KantongStarted event,
    Emitter<KantongState> emit,
  ) async {
    emit(state.copyWith(status: KantongStatus.loading));
    try {
      final pockets = await _repository.getPockets();
      emit(state.copyWith(status: KantongStatus.success, pockets: pockets));
    } catch (e) {
      emit(state.copyWith(
        status: KantongStatus.failure,
        failure: AppFailure.loadPocketsFailed,
      ));
    }
  }
}
