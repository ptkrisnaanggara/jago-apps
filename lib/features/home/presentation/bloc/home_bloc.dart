import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/account.dart';
import '../../data/models/shortcut.dart';
import '../../data/repositories/account_repository.dart';
import '../../../transactions/data/models/transaction.dart';
import '../../../transactions/data/repositories/transaction_repository.dart';

part 'home_event.dart';
part 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final AccountRepository _accountRepository;
  final TransactionRepository _transactionRepository;

  HomeBloc({
    required AccountRepository accountRepository,
    required TransactionRepository transactionRepository,
  })  : _accountRepository = accountRepository,
        _transactionRepository = transactionRepository,
        super(const HomeState()) {
    on<HomeStarted>(_onStarted);
  }

  Future<void> _onStarted(HomeStarted event, Emitter<HomeState> emit) async {
    emit(state.copyWith(status: HomeStatus.loading));
    try {
      final results = await Future.wait([
        _accountRepository.getAccount(),
        _accountRepository.getShortcuts(),
        _transactionRepository.getTransactions(),
      ]);
      final account = results[0] as Account;
      final shortcuts = results[1] as List<Shortcut>;
      final transactions = results[2] as List<TransactionItem>;

      emit(state.copyWith(
        status: HomeStatus.success,
        account: account,
        shortcuts: shortcuts,
        recentTransactions: transactions.take(3).toList(),
      ));
    } catch (e) {
      emit(state.copyWith(
        status: HomeStatus.failure,
        errorMessage: 'Gagal memuat data. Coba lagi.',
      ));
    }
  }
}
