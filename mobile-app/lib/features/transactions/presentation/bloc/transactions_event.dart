part of 'transactions_bloc.dart';

sealed class TransactionsEvent extends Equatable {
  const TransactionsEvent();

  @override
  List<Object?> get props => [];
}

class TransactionsStarted extends TransactionsEvent {
  const TransactionsStarted();
}

class TransactionsFilterChanged extends TransactionsEvent {
  final TransactionFilter filter;

  const TransactionsFilterChanged(this.filter);

  @override
  List<Object?> get props => [filter];
}
