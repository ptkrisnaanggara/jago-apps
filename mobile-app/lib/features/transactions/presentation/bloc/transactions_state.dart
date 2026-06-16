part of 'transactions_bloc.dart';

enum TransactionsStatus { initial, loading, success, failure }

/// Transaction history filter.
enum TransactionFilter {
  all,
  income,
  expense;

  /// Backend `?type=` value (null for "all").
  String? get type => switch (this) {
        TransactionFilter.income => 'income',
        TransactionFilter.expense => 'expense',
        TransactionFilter.all => null,
      };
}

class TransactionsState extends Equatable {
  final TransactionsStatus status;
  final List<TransactionItem> transactions;
  final TransactionFilter filter;
  final AppFailure? failure;

  const TransactionsState({
    this.status = TransactionsStatus.initial,
    this.transactions = const [],
    this.filter = TransactionFilter.all,
    this.failure,
  });

  TransactionsState copyWith({
    TransactionsStatus? status,
    List<TransactionItem>? transactions,
    TransactionFilter? filter,
    AppFailure? failure,
  }) {
    return TransactionsState(
      status: status ?? this.status,
      transactions: transactions ?? this.transactions,
      filter: filter ?? this.filter,
      failure: failure,
    );
  }

  @override
  List<Object?> get props => [status, transactions, filter, failure];
}
