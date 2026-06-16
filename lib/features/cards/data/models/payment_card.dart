import 'package:equatable/equatable.dart';

enum CardType { virtual, physical }

/// A debit/payment card tied to the account.
class PaymentCard extends Equatable {
  final String id;
  final String label;
  final String number; // full PAN, e.g. "4567 8901 2345 6789"
  final String holderName;
  final String expiry; // MM/YY
  final String cvv;
  final CardType type;
  final bool isFrozen;

  /// Index into `AppColors.pocketAccents`, used for the card gradient.
  final int accentIndex;

  const PaymentCard({
    required this.id,
    required this.label,
    required this.number,
    required this.holderName,
    required this.expiry,
    required this.cvv,
    required this.type,
    this.isFrozen = false,
    this.accentIndex = 0,
  });

  /// Last 4 digits with the rest masked, e.g. "•••• •••• •••• 6789".
  String get maskedNumber {
    final last4 = number.replaceAll(' ', '');
    final tail = last4.length >= 4 ? last4.substring(last4.length - 4) : last4;
    return '•••• •••• •••• $tail';
  }

  PaymentCard copyWith({bool? isFrozen}) {
    return PaymentCard(
      id: id,
      label: label,
      number: number,
      holderName: holderName,
      expiry: expiry,
      cvv: cvv,
      type: type,
      isFrozen: isFrozen ?? this.isFrozen,
      accentIndex: accentIndex,
    );
  }

  @override
  List<Object?> get props =>
      [id, label, number, holderName, expiry, cvv, type, isFrozen, accentIndex];
}
