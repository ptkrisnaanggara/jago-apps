part of 'home_bloc.dart';

enum HomeStatus { initial, loading, success, failure }

class HomeState extends Equatable {
  final HomeStatus status;
  final Account? account;
  final List<Shortcut> shortcuts;
  final List<TransactionItem> recentTransactions;
  final String? errorMessage;

  const HomeState({
    this.status = HomeStatus.initial,
    this.account,
    this.shortcuts = const [],
    this.recentTransactions = const [],
    this.errorMessage,
  });

  HomeState copyWith({
    HomeStatus? status,
    Account? account,
    List<Shortcut>? shortcuts,
    List<TransactionItem>? recentTransactions,
    String? errorMessage,
  }) {
    return HomeState(
      status: status ?? this.status,
      account: account ?? this.account,
      shortcuts: shortcuts ?? this.shortcuts,
      recentTransactions: recentTransactions ?? this.recentTransactions,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props =>
      [status, account, shortcuts, recentTransactions, errorMessage];
}
