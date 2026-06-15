part of 'transfer_bloc.dart';

enum TransferStatus {
  initial,
  loading,
  success,
  failure,
  submitting,
  completed,
}

class TransferState extends Equatable {
  final TransferStatus status;
  final List<Contact> contacts;
  final String query;
  final Contact? selectedContact;
  final double amount;
  final String note;
  final TransferResult? result;
  final String? errorMessage;

  const TransferState({
    this.status = TransferStatus.initial,
    this.contacts = const [],
    this.query = '',
    this.selectedContact,
    this.amount = 0,
    this.note = '',
    this.result,
    this.errorMessage,
  });

  /// Contacts filtered by [query] (matches name, bank, or account number).
  List<Contact> get filteredContacts {
    if (query.trim().isEmpty) return contacts;
    final q = query.toLowerCase();
    return contacts
        .where((c) =>
            c.name.toLowerCase().contains(q) ||
            c.bankName.toLowerCase().contains(q) ||
            c.accountNumber.replaceAll(' ', '').contains(q.replaceAll(' ', '')))
        .toList();
  }

  TransferState copyWith({
    TransferStatus? status,
    List<Contact>? contacts,
    String? query,
    Contact? selectedContact,
    double? amount,
    String? note,
    TransferResult? result,
    String? errorMessage,
  }) {
    return TransferState(
      status: status ?? this.status,
      contacts: contacts ?? this.contacts,
      query: query ?? this.query,
      selectedContact: selectedContact ?? this.selectedContact,
      amount: amount ?? this.amount,
      note: note ?? this.note,
      result: result ?? this.result,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        contacts,
        query,
        selectedContact,
        amount,
        note,
        result,
        errorMessage,
      ];
}
