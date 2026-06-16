import 'package:equatable/equatable.dart';

/// Authenticated user identity.
class AuthUser extends Equatable {
  final String id;
  final String name;
  final String phone;

  const AuthUser({
    required this.id,
    required this.name,
    required this.phone,
  });

  @override
  List<Object?> get props => [id, name, phone];
}
