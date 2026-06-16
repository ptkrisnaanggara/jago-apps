import 'package:equatable/equatable.dart';

/// A prepaid product (pulsa / data). [amount] is the price.
class TopupProduct extends Equatable {
  final String id;
  final String type; // 'pulsa' | 'data'
  final String name;
  final double amount;

  const TopupProduct({
    required this.id,
    required this.type,
    required this.name,
    required this.amount,
  });

  @override
  List<Object?> get props => [id, type, name, amount];
}

/// Receipt for a completed top-up.
class TopupReceipt extends Equatable {
  final String productName;
  final String type;
  final String phone;
  final double amount;
  final String pocketName;
  final String referenceId;
  final DateTime paidAt;

  const TopupReceipt({
    required this.productName,
    required this.type,
    required this.phone,
    required this.amount,
    required this.pocketName,
    required this.referenceId,
    required this.paidAt,
  });

  @override
  List<Object?> get props =>
      [productName, type, phone, amount, pocketName, referenceId, paidAt];
}
