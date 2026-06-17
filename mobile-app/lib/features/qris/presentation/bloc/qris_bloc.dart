import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jago/core/errors/app_failure.dart';
import 'package:jago/features/kantong/data/models/pocket.dart';
import 'package:jago/features/kantong/data/repositories/pocket_repository.dart';

import '../../data/models/qris_models.dart';
import '../../data/repositories/qris_repository.dart';

part 'qris_event.dart';
part 'qris_state.dart';

/// Drives the QRIS flow: load payable pockets → parse a payload → pay.
class QrisBloc extends Bloc<QrisEvent, QrisState> {
  final QrisRepository _qris;
  final PocketRepository _pockets;

  QrisBloc({required QrisRepository qris, required PocketRepository pockets})
      : _qris = qris,
        _pockets = pockets,
        super(const QrisState()) {
    on<QrisStarted>(_onStarted);
    on<QrisParseRequested>(_onParse);
    on<QrisPaid>(_onPaid);
  }

  Future<void> _onStarted(QrisStarted event, Emitter<QrisState> emit) async {
    emit(state.copyWith(status: QrisStatus.loading));
    try {
      final all = await _pockets.getPockets();
      final payable = all
          .where((p) =>
              p.type == PocketType.main || p.type == PocketType.spending)
          .toList();
      emit(state.copyWith(status: QrisStatus.ready, pockets: payable));
    } catch (_) {
      emit(state.copyWith(status: QrisStatus.failure, failure: AppFailure.qrisFailed));
    }
  }

  Future<void> _onParse(
    QrisParseRequested event,
    Emitter<QrisState> emit,
  ) async {
    emit(state.copyWith(status: QrisStatus.parsing, payload: event.payload));
    try {
      final info = await _qris.parse(event.payload);
      emit(state.copyWith(status: QrisStatus.review, info: info));
    } catch (_) {
      emit(state.copyWith(status: QrisStatus.ready, failure: AppFailure.qrisFailed));
    }
  }

  Future<void> _onPaid(QrisPaid event, Emitter<QrisState> emit) async {
    emit(state.copyWith(status: QrisStatus.paying));
    try {
      final receipt = await _qris.pay(
        payload: state.payload,
        pocketId: event.pocketId,
        amount: event.amount,
      );
      emit(state.copyWith(status: QrisStatus.success, receipt: receipt));
    } catch (_) {
      emit(state.copyWith(status: QrisStatus.review, failure: AppFailure.qrisFailed));
    }
  }
}
