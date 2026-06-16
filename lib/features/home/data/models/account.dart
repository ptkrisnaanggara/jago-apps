import 'package:equatable/equatable.dart';

/// The user's primary account summary shown on Home.
class Account extends Equatable {
  final String holderName;
  final String accountNumber;
  final double balance;

  const Account({
    required this.holderName,
    required this.accountNumber,
    required this.balance,
  });

  @override
  List<Object?> get props => [holderName, accountNumber, balance];
}
