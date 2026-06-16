import 'package:equatable/equatable.dart';

import 'contact.dart';

/// Receipt returned after a successful transfer.
class TransferResult extends Equatable {
  final String referenceId;
  final Contact contact;
  final double amount;
  final String note;
  final DateTime timestamp;

  const TransferResult({
    required this.referenceId,
    required this.contact,
    required this.amount,
    required this.note,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [referenceId, contact, amount, note, timestamp];
}
