import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jago/features/security/data/pin_store.dart';
import 'package:jago/features/security/presentation/bloc/security_bloc.dart';

void main() {
  group('SecurityBloc', () {
    test('no PIN set → not locked after start', () async {
      final bloc = SecurityBloc(store: InMemoryPinStore())
        ..add(const SecurityStarted());
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state.pinSet, isFalse);
      expect(bloc.state.locked, isFalse);
    });

    blocTest<SecurityBloc, SecurityState>(
      'creating a PIN sets it and unlocks',
      build: () => SecurityBloc(store: InMemoryPinStore()),
      act: (bloc) => bloc.add(const PinCreated('123456')),
      wait: const Duration(milliseconds: 50),
      verify: (bloc) {
        expect(bloc.state.pinSet, isTrue);
        expect(bloc.state.locked, isFalse);
      },
    );

    test('a set PIN locks on next start; wrong rejects, correct unlocks', () async {
      final store = InMemoryPinStore();
      // First session sets the PIN.
      SecurityBloc(store: store).add(const PinCreated('246810'));
      await Future<void>.delayed(Duration.zero);

      // New session (simulated restart) loads + locks.
      final s2 = SecurityBloc(store: store)..add(const SecurityStarted());
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
  });
}
