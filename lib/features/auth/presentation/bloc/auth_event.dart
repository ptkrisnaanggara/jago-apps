part of 'auth_bloc.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Restore any existing session on app start.
class AuthStarted extends AuthEvent {
  const AuthStarted();
}

/// Request an OTP for [phone]. [name] is set during sign-up.
class AuthOtpRequested extends AuthEvent {
  final String phone;
  final String? name;

  const AuthOtpRequested({required this.phone, this.name});

  @override
  List<Object?> get props => [phone, name];
}

/// Submit the OTP [code] entered by the user.
class AuthOtpSubmitted extends AuthEvent {
  final String code;

  const AuthOtpSubmitted(this.code);

  @override
  List<Object?> get props => [code];
}

class AuthSignedOut extends AuthEvent {
  const AuthSignedOut();
}
