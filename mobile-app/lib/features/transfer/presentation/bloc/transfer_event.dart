part of 'transfer_bloc.dart';

sealed class TransferEvent extends Equatable {
  const TransferEvent();

  @override
  List<Object?> get props => [];
}

/// Load the contact list.
class TransferStarted extends TransferEvent {
  const TransferStarted();
}

class TransferSearchChanged extends TransferEvent {
  final String query;

  const TransferSearchChanged(this.query);

  @override
  List<Object?> get props => [query];
}

class TransferContactSelected extends TransferEvent {
  final Contact contact;

  const TransferContactSelected(this.contact);

  @override
  List<Object?> get props => [contact];
}

/// Store the amount + note before confirmation.
class TransferDetailsEntered extends TransferEvent {
  final double amount;
  final String note;

  const TransferDetailsEntered({required this.amount, required this.note});

  @override
  List<Object?> get props => [amount, note];
}

/// Submit the transfer.
class TransferConfirmed extends TransferEvent {
  const TransferConfirmed();
}
