part of 'auth_bloc.dart';

enum AuthStatus {
  /// Session restore in progress (app start).
  unknown,
  unauthenticated,
  requestingOtp,
  otpSent,
  verifying,
  authenticated,
  failure,
}

class AuthState extends Equatable {
  final AuthStatus status;
  final String? pendingPhone;
  final String? pendingName;
  final AuthUser? user;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.unknown,
    this.pendingPhone,
    this.pendingName,
    this.user,
    this.errorMessage,
  });

  AuthState copyWith({
    AuthStatus? status,
    String? pendingPhone,
    String? pendingName,
    AuthUser? user,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      pendingPhone: pendingPhone ?? this.pendingPhone,
      pendingName: pendingName ?? this.pendingName,
      user: user ?? this.user,
      // errorMessage is intentionally not carried over: each transition
      // sets it explicitly (or leaves it null) so stale errors don't linger.
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props =>
      [status, pendingPhone, pendingName, user, errorMessage];
}
