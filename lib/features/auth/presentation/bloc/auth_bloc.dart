import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/auth_user.dart';
import '../../data/repositories/auth_repository.dart';

part 'auth_event.dart';
part 'auth_state.dart';

/// Owns the app's authentication state. Lives above the router so `go_router`
/// can redirect based on [AuthState.status].
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _repository;

  AuthBloc({required AuthRepository repository})
      : _repository = repository,
        super(const AuthState()) {
    on<AuthStarted>(_onStarted);
    on<AuthOtpRequested>(_onOtpRequested);
    on<AuthOtpSubmitted>(_onOtpSubmitted);
    on<AuthSignedOut>(_onSignedOut);
  }

  Future<void> _onStarted(AuthStarted event, Emitter<AuthState> emit) async {
    final user = await _repository.currentUser();
    emit(user == null
        ? const AuthState(status: AuthStatus.unauthenticated)
        : AuthState(status: AuthStatus.authenticated, user: user));
  }

  Future<void> _onOtpRequested(
    AuthOtpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.requestingOtp));
    try {
      await _repository.requestOtp(event.phone);
      emit(state.copyWith(
        status: AuthStatus.otpSent,
        pendingPhone: event.phone,
        pendingName: event.name,
      ));
    } catch (_) {
      emit(state.copyWith(
        status: AuthStatus.failure,
        errorMessage: 'Gagal mengirim OTP. Coba lagi.',
      ));
    }
  }

  Future<void> _onOtpSubmitted(
    AuthOtpSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.verifying));
    try {
      final user = await _repository.verifyOtp(
        phone: state.pendingPhone ?? '',
        code: event.code,
        name: state.pendingName,
      );
      emit(AuthState(status: AuthStatus.authenticated, user: user));
    } catch (_) {
      emit(state.copyWith(
        status: AuthStatus.otpSent,
        errorMessage: 'Kode OTP salah. Coba lagi.',
      ));
    }
  }

  Future<void> _onSignedOut(
    AuthSignedOut event,
    Emitter<AuthState> emit,
  ) async {
    await _repository.signOut();
    emit(const AuthState(status: AuthStatus.unauthenticated));
  }
}
