import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/app_failure.dart';
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
    on<TransactionsFilterChanged>(_onFilterChanged);
  }

  Future<void> _onStarted(
    TransactionsStarted event,
    Emitter<TransactionsState> emit,
  ) =>
      _load(state.filter, emit);

  Future<void> _onFilterChanged(
    TransactionsFilterChanged event,
    Emitter<TransactionsState> emit,
  ) {
    emit(state.copyWith(filter: event.filter));
    return _load(event.filter, emit);
  }

  Future<void> _load(
    TransactionFilter filter,
    Emitter<TransactionsState> emit,
  ) async {
    emit(state.copyWith(status: TransactionsStatus.loading));
    try {
      final items = await _repository.getTransactions(type: filter.type);
      emit(state.copyWith(
        status: TransactionsStatus.success,
        transactions: items,
      ));
    } catch (_) {
      emit(state.copyWith(
        status: TransactionsStatus.failure,
        failure: AppFailure.loadTransactionsFailed,
      ));
    }
  }
}
