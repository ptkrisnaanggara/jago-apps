import 'package:equatable/equatable.dart';

/// How often a bill repeats.
enum BillRecurrence { none, weekly, monthly }

extension BillRecurrenceLabel on BillRecurrence {
  String get label => switch (this) {
        BillRecurrence.none => 'Sekali',
        BillRecurrence.weekly => 'Mingguan',
        BillRecurrence.monthly => 'Bulanan',
      };
}

/// A scheduled bill / payment plan.
class Bill extends Equatable {
  final String id;
  final String biller;
  final String category;
  final double amount;
  final DateTime dueDate;
  final bool isPaid;
  final BillRecurrence recurrence;

  const Bill({
    required this.id,
    required this.biller,
    required this.category,
    required this.amount,
    required this.dueDate,
    this.isPaid = false,
    this.recurrence = BillRecurrence.none,
  });

  /// Unpaid and past its due date.
  bool get isOverdue => !isPaid && dueDate.isBefore(DateTime.now());

  bool get isRecurring => recurrence != BillRecurrence.none;

  Bill copyWith({bool? isPaid}) {
    return Bill(
      id: id,
      biller: biller,
      category: category,
      amount: amount,
      dueDate: dueDate,
      isPaid: isPaid ?? this.isPaid,
      recurrence: recurrence,
    );
  }

  @override
  List<Object?> get props =>
      [id, biller, category, amount, dueDate, isPaid, recurrence];
}
