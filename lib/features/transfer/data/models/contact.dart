import 'package:equatable/equatable.dart';

/// A transfer recipient (saved contact / payee).
class Contact extends Equatable {
  final String id;
  final String name;
  final String bankName;
  final String accountNumber;

  const Contact({
    required this.id,
    required this.name,
    required this.bankName,
    required this.accountNumber,
  });

  /// First letter, for avatar fallbacks.
  String get initial => name.isNotEmpty ? name[0].toUpperCase() : '?';

  @override
  List<Object?> get props => [id, name, bankName, accountNumber];
}
