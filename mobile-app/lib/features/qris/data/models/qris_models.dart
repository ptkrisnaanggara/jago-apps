import 'package:equatable/equatable.dart';

/// Decoded QRIS payload. [dynamic_] is true when the QR carries a fixed amount.
class QrisInfo extends Equatable {
  final String merchantName;
  final String merchantCity;
  final double amount;
  final bool dynamic_;

  const QrisInfo({
    required this.merchantName,
    required this.merchantCity,
    required this.amount,
    required this.dynamic_,
  });

  @override
  List<Object?> get props => [merchantName, merchantCity, amount, dynamic_];
}

/// Receipt for a completed QRIS payment.
class QrisReceipt extends Equatable {
  final String merchantName;
  final String merchantCity;
  final double amount;
  final String pocketName;
  final String referenceId;
  final DateTime paidAt;

  const QrisReceipt({
    required this.merchantName,
    required this.merchantCity,
    required this.amount,
    required this.pocketName,
    required this.referenceId,
    required this.paidAt,
  });

  @override
  List<Object?> get props =>
      [merchantName, merchantCity, amount, pocketName, referenceId, paidAt];
}
