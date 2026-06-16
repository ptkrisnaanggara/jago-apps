import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jago/features/transactions/data/models/transaction.dart';
import 'package:jago/features/transactions/data/repositories/transaction_repository.dart';
import 'package:jago/features/transactions/presentation/bloc/transactions_bloc.dart';

void main() {
  group('TransactionsBloc', () {
    blocTest<TransactionsBloc, TransactionsState>(
      'loads all transactions on start',
      build: () => TransactionsBloc(repository: MockTransactionRepository()),
      act: (bloc) => bloc.add(const TransactionsStarted()),
      wait: const Duration(milliseconds: 800),
      verify: (bloc) {
        expect(bloc.state.status, TransactionsStatus.success);
        expect(bloc.state.transactions, isNotEmpty);
        expect(bloc.state.filter, TransactionFilter.all);
      },
    );

    blocTest<TransactionsBloc, TransactionsState>(
      'expense filter returns only expenses',
      build: () => TransactionsBloc(repository: MockTransactionRepository()),
      act: (bloc) async {
        bloc.add(const TransactionsStarted());
        await Future<void>.delayed(const Duration(milliseconds: 700));
        bloc.add(const TransactionsFilterChanged(TransactionFilter.expense));
      },
      wait: const Duration(milliseconds: 1500),
      verify: (bloc) {
        expect(bloc.state.filter, TransactionFilter.expense);
        expect(bloc.state.transactions, isNotEmpty);
        expect(
          bloc.state.transactions
              .every((t) => t.type == TransactionType.expense),
          isTrue,
        );
      },
    );
  });
}
