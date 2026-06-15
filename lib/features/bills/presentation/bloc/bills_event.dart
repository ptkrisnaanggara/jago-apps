part of 'bills_bloc.dart';

sealed class BillsEvent extends Equatable {
  const BillsEvent();

  @override
  List<Object?> get props => [];
}

class BillsStarted extends BillsEvent {
  const BillsStarted();
}

class BillPaid extends BillsEvent {
  final String id;

  const BillPaid(this.id);

  @override
  List<Object?> get props => [id];
}

class BillScheduled extends BillsEvent {
  final Bill bill;

  const BillScheduled(this.bill);

  @override
  List<Object?> get props => [bill];
}
