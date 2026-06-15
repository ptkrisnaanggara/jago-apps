part of 'transactions_bloc.dart';

enum TransactionsStatus { initial, loading, success, failure }

class TransactionsState extends Equatable {
  final TransactionsStatus status;
  final List<TransactionItem> transactions;
  final AppFailure? failure;

  const TransactionsState({
    this.status = TransactionsStatus.initial,
    this.transactions = const [],
    this.failure,
  });

  TransactionsState copyWith({
    TransactionsStatus? status,
    List<TransactionItem>? transactions,
    AppFailure? failure,
  }) {
    return TransactionsState(
      status: status ?? this.status,
      transactions: transactions ?? this.transactions,
      failure: failure ?? this.failure,
    );
  }

  @override
  List<Object?> get props => [status, transactions, failure];
}
