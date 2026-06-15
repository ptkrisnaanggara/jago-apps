import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/transaction.dart';
import '../../data/repositories/transaction_repository.dart';

part 'transactions_event.dart';
part 'transactions_state.dart';

class TransactionsBloc extends Bloc<TransactionsEvent, TransactionsState> {
  final TransactionRepository _repository;

  TransactionsBloc({required TransactionRepository repository})
      : _repository = repository,
        super(const TransactionsState()) {
    on<TransactionsStarted>(_onStarted);
  }

  Future<void> _onStarted(
    TransactionsStarted event,
    Emitter<TransactionsState> emit,
  ) async {
    emit(state.copyWith(status: TransactionsStatus.loading));
    try {
      final items = await _repository.getTransactions();
      emit(state.copyWith(
        status: TransactionsStatus.success,
        transactions: items,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: TransactionsStatus.failure,
        errorMessage: 'Gagal memuat transaksi. Coba lagi.',
      ));
    }
  }
}
