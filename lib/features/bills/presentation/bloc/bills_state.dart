part of 'bills_bloc.dart';

enum BillsStatus { initial, loading, success, failure }

class BillsState extends Equatable {
  final BillsStatus status;
  final List<Bill> bills;

  /// Id of the bill currently being paid (drives a per-tile spinner).
  final String? payingId;
  final String? errorMessage;

  const BillsState({
    this.status = BillsStatus.initial,
    this.bills = const [],
    this.payingId,
    this.errorMessage,
  });

  /// Unpaid bills, earliest due first (overdue naturally sort to the top).
  List<Bill> get upcomingBills {
    final list = bills.where((b) => !b.isPaid).toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    return list;
  }

  List<Bill> get paidBills => bills.where((b) => b.isPaid).toList();

  double get totalUpcoming =>
      upcomingBills.fold(0, (sum, b) => sum + b.amount);

  BillsState copyWith({
    BillsStatus? status,
    List<Bill>? bills,
    String? payingId,
    String? errorMessage,
  }) {
    return BillsState(
      status: status ?? this.status,
      bills: bills ?? this.bills,
      // payingId and errorMessage reset each transition unless set explicitly.
      payingId: payingId,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, bills, payingId, errorMessage];
}
