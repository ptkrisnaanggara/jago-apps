import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/app_failure.dart';
import '../../data/models/contact.dart';
import '../../data/models/transfer_result.dart';
import '../../data/repositories/transfer_repository.dart';

part 'transfer_event.dart';
part 'transfer_state.dart';

/// Drives the multi-step Transfer & Pay flow: load contacts → select →
/// enter amount → confirm → receipt. Provided once over the transfer routes
/// so selection survives navigation between steps.
class TransferBloc extends Bloc<TransferEvent, TransferState> {
  final TransferRepository _repository;

  TransferBloc({required TransferRepository repository})
      : _repository = repository,
        super(const TransferState()) {
    on<TransferStarted>(_onStarted);
    on<TransferSearchChanged>(_onSearchChanged);
    on<TransferContactSelected>(_onContactSelected);
    on<TransferDetailsEntered>(_onDetailsEntered);
    on<TransferConfirmed>(_onConfirmed);
  }

  Future<void> _onStarted(
    TransferStarted event,
    Emitter<TransferState> emit,
  ) async {
    emit(state.copyWith(status: TransferStatus.loading));
    try {
      final contacts = await _repository.getContacts();
      emit(state.copyWith(
        status: TransferStatus.success,
        contacts: contacts,
      ));
    } catch (_) {
      emit(state.copyWith(
        status: TransferStatus.failure,
        failure: AppFailure.loadContactsFailed,
      ));
    }
  }

  void _onSearchChanged(
    TransferSearchChanged event,
    Emitter<TransferState> emit,
  ) {
    emit(state.copyWith(query: event.query));
  }

  void _onContactSelected(
    TransferContactSelected event,
    Emitter<TransferState> emit,
  ) {
    emit(state.copyWith(selectedContact: event.contact));
  }

  void _onDetailsEntered(
    TransferDetailsEntered event,
    Emitter<TransferState> emit,
  ) {
    emit(state.copyWith(amount: event.amount, note: event.note));
  }

  Future<void> _onConfirmed(
    TransferConfirmed event,
    Emitter<TransferState> emit,
  ) async {
    final contact = state.selectedContact;
    if (contact == null || state.amount <= 0) return;
    emit(state.copyWith(status: TransferStatus.submitting));
    try {
      final result = await _repository.submitTransfer(
        contact: contact,
        amount: state.amount,
        note: state.note,
      );
      emit(state.copyWith(status: TransferStatus.completed, result: result));
    } catch (_) {
      emit(state.copyWith(
        status: TransferStatus.failure,
        failure: AppFailure.transferFailed,
      ));
    }
  }
}
