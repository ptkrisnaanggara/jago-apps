import 'package:equatable/equatable.dart';

enum TransactionType { income, expense }

/// A single money movement in the account history.
class TransactionItem extends Equatable {
  final String id;
  final String title;
  final String category;
  final double amount;
  final TransactionType type;
  final DateTime date;

  const TransactionItem({
    required this.id,
    required this.title,
    required this.category,
    required this.amount,
    required this.type,
    required this.date,
  });

  bool get isIncome => type == TransactionType.income;

  @override
  List<Object?> get props => [id, title, category, amount, type, date];
}
