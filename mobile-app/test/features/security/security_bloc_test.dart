import 'package:flutter_test/flutter_test.dart';
import 'package:jago/features/security/data/biometric_auth.dart';
import 'package:jago/features/security/data/pin_store.dart';
import 'package:jago/features/security/presentation/bloc/security_bloc.dart';

/// Fake biometrics: configurable availability + auth result.
class _FakeBiometric implements BiometricAuth {
  final bool available;
  final bool authResult;
  const _FakeBiometric({this.available = true, this.authResult = true});

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<bool> authenticate(String reason) async => authResult;
}

void main() {
  SecurityBloc build({BiometricAuth? bio, PinStore? store}) => SecurityBloc(
        store: store ?? InMemoryPinStore(),
        biometric: bio ?? const NoBiometric(),
      );

  group('SecurityBloc', () {
    test('no PIN set → not locked after start', () async {
      final bloc = build()..add(const SecurityStarted());
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state.pinSet, isFalse);
      expect(bloc.state.locked, isFalse);
    });

    test('a set PIN locks on next start; wrong rejects, correct unlocks', () async {
      final store = InMemoryPinStore();
      build(store: store).add(const PinCreated('246810'));
      await Future<void>.delayed(Duration.zero);

      final s2 = build(store: store)..add(const SecurityStarted());
      await Future<void>.delayed(Duration.zero);
      expect(s2.state.locked, isTrue);

      s2.add(const PinUnlockRequested('000000'));
      await Future<void>.delayed(Duration.zero);
      expect(s2.state.locked, isTrue);
      expect(s2.state.lastAttemptFailed, isTrue);

      s2.add(const PinUnlockRequested('246810'));
      await Future<void>.delayed(Duration.zero);
      expect(s2.state.locked, isFalse);
    });

    test('biometric: enable then unlock succeeds', () async {
      final store = InMemoryPinStore();
      await store.saveHash('x'); // a PIN exists
      final bloc = build(
        store: store,
        bio: const _FakeBiometric(available: true, authResult: true),
      )..add(const SecurityStarted());
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state.locked, isTrue);
      expect(bloc.state.biometricAvailable, isTrue);

      bloc.add(const BiometricToggled(true));
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state.biometricEnabled, isTrue);

      bloc.add(const BiometricUnlockRequested());
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state.locked, isFalse);
    });

    test('biometric unavailable → cannot enable', () async {
      final bloc = build(bio: const _FakeBiometric(available: false))
        ..add(const SecurityStarted());
      await Future<void>.delayed(Duration.zero);
      bloc.add(const BiometricToggled(true));
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state.biometricEnabled, isFalse);
    });
  });
}
