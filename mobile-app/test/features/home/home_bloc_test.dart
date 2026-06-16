import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jago/features/home/data/repositories/account_repository.dart';
import 'package:jago/features/home/presentation/bloc/home_bloc.dart';
import 'package:jago/features/transactions/data/repositories/transaction_repository.dart';

void main() {
  group('HomeBloc', () {
    test('initial state is HomeStatus.initial', () {
      final bloc = HomeBloc(
        accountRepository: MockAccountRepository(),
        transactionRepository: MockTransactionRepository(),
      );
      expect(bloc.state.status, HomeStatus.initial);
    });

    blocTest<HomeBloc, HomeState>(
      'emits [loading, success] with account + 3 recent transactions',
      build: () => HomeBloc(
        accountRepository: MockAccountRepository(),
        transactionRepository: MockTransactionRepository(),
      ),
      act: (bloc) => bloc.add(const HomeStarted()),
      wait: const Duration(milliseconds: 900),
      expect: () => [
        isA<HomeState>().having((s) => s.status, 'status', HomeStatus.loading),
        isA<HomeState>()
            .having((s) => s.status, 'status', HomeStatus.success)
            .having((s) => s.account, 'account', isNotNull)
            .having((s) => s.recentTransactions.length, 'recent', 3),
      ],
    );
  });
}
