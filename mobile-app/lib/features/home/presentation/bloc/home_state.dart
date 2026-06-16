part of 'home_bloc.dart';

enum HomeStatus { initial, loading, success, failure }

class HomeState extends Equatable {
  final HomeStatus status;
  final Account? account;
  final List<Shortcut> shortcuts;
  final List<TransactionItem> recentTransactions;
  final AppFailure? failure;

  const HomeState({
    this.status = HomeStatus.initial,
    this.account,
    this.shortcuts = const [],
    this.recentTransactions = const [],
    this.failure,
  });

  HomeState copyWith({
    HomeStatus? status,
    Account? account,
    List<Shortcut>? shortcuts,
    List<TransactionItem>? recentTransactions,
    AppFailure? failure,
  }) {
    return HomeState(
      status: status ?? this.status,
      account: account ?? this.account,
      shortcuts: shortcuts ?? this.shortcuts,
      recentTransactions: recentTransactions ?? this.recentTransactions,
      failure: failure ?? this.failure,
    );
  }

  @override
  List<Object?> get props =>
      [status, account, shortcuts, recentTransactions, failure];
}
