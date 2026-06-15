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
  final AppFailure? failure;

  const AuthState({
    this.status = AuthStatus.unknown,
    this.pendingPhone,
    this.pendingName,
    this.user,
    this.failure,
  });

  AuthState copyWith({
    AuthStatus? status,
    String? pendingPhone,
    String? pendingName,
    AuthUser? user,
    AppFailure? failure,
  }) {
    return AuthState(
      status: status ?? this.status,
      pendingPhone: pendingPhone ?? this.pendingPhone,
      pendingName: pendingName ?? this.pendingName,
      user: user ?? this.user,
      // failure is intentionally not carried over: each transition sets it
      // explicitly (or leaves it null) so stale errors don't linger.
      failure: failure,
    );
  }

  @override
  List<Object?> get props =>
      [status, pendingPhone, pendingName, user, failure];
}
