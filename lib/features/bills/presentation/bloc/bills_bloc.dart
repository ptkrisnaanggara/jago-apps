import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/bill.dart';
import '../../data/repositories/bills_repository.dart';

part 'bills_event.dart';
part 'bills_state.dart';

class BillsBloc extends Bloc<BillsEvent, BillsState> {
  final BillsRepository _repository;

  BillsBloc({required BillsRepository repository})
      : _repository = repository,
        super(const BillsState()) {
    on<BillsStarted>(_onStarted);
    on<BillPaid>(_onPaid);
    on<BillScheduled>(_onScheduled);
  }

  Future<void> _onStarted(BillsStarted event, Emitter<BillsState> emit) async {
    emit(state.copyWith(status: BillsStatus.loading));
    try {
      final bills = await _repository.getBills();
      emit(state.copyWith(status: BillsStatus.success, bills: bills));
    } catch (_) {
      emit(state.copyWith(
        status: BillsStatus.failure,
        errorMessage: 'Gagal memuat tagihan. Coba lagi.',
      ));
    }
  }

  Future<void> _onPaid(BillPaid event, Emitter<BillsState> emit) async {
    emit(state.copyWith(payingId: event.id));
    try {
      final bills = await _repository.payBill(event.id);
      emit(state.copyWith(status: BillsStatus.success, bills: bills));
    } catch (_) {
      emit(state.copyWith(errorMessage: 'Pembayaran gagal. Coba lagi.'));
    }
  }

  Future<void> _onScheduled(
    BillScheduled event,
    Emitter<BillsState> emit,
  ) async {
    try {
      final bills = await _repository.scheduleBill(event.bill);
      emit(state.copyWith(status: BillsStatus.success, bills: bills));
    } catch (_) {
      emit(state.copyWith(errorMessage: 'Gagal menyimpan rencana. Coba lagi.'));
    }
  }
}
