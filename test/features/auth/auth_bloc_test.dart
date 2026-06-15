import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jago/features/auth/data/repositories/auth_repository.dart';
import 'package:jago/features/auth/presentation/bloc/auth_bloc.dart';

void main() {
  group('AuthBloc', () {
    blocTest<AuthBloc, AuthState>(
      'AuthStarted resolves to unauthenticated when no session exists',
      build: () => AuthBloc(repository: MockAuthRepository()),
      act: (bloc) => bloc.add(const AuthStarted()),
      wait: const Duration(milliseconds: 800),
      expect: () => [
        isA<AuthState>()
            .having((s) => s.status, 'status', AuthStatus.unauthenticated),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'OTP flow with the demo code ends authenticated',
      build: () => AuthBloc(repository: MockAuthRepository()),
      act: (bloc) async {
        bloc.add(const AuthOtpRequested(phone: '81234567890'));
        await Future<void>.delayed(const Duration(milliseconds: 800));
        bloc.add(const AuthOtpSubmitted('123456'));
      },
      wait: const Duration(milliseconds: 1600),
      expect: () => [
        isA<AuthState>()
            .having((s) => s.status, 'status', AuthStatus.requestingOtp),
        isA<AuthState>().having((s) => s.status, 'status', AuthStatus.otpSent),
        isA<AuthState>()
            .having((s) => s.status, 'status', AuthStatus.verifying),
        isA<AuthState>()
            .having((s) => s.status, 'status', AuthStatus.authenticated)
            .having((s) => s.user, 'user', isNotNull),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'wrong OTP returns to otpSent with an error message',
      build: () => AuthBloc(repository: MockAuthRepository()),
      act: (bloc) async {
        bloc.add(const AuthOtpRequested(phone: '81234567890'));
        await Future<void>.delayed(const Duration(milliseconds: 800));
        bloc.add(const AuthOtpSubmitted('000000'));
      },
      wait: const Duration(milliseconds: 1600),
      expect: () => [
        isA<AuthState>()
            .having((s) => s.status, 'status', AuthStatus.requestingOtp),
        isA<AuthState>().having((s) => s.status, 'status', AuthStatus.otpSent),
        isA<AuthState>()
            .having((s) => s.status, 'status', AuthStatus.verifying),
        isA<AuthState>()
            .having((s) => s.status, 'status', AuthStatus.otpSent)
            .having((s) => s.failure, 'failure', isNotNull),
      ],
    );
  });
}
