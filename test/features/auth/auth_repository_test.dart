import 'package:flutter_test/flutter_test.dart';
import 'package:jago/features/auth/data/repositories/auth_repository.dart';
import 'package:jago/features/auth/data/sources/auth_session_store.dart';

void main() {
  group('MockAuthRepository session persistence', () {
    test('verifyOtp saves a session that survives a new instance', () async {
      // A shared store stands in for persistent storage across "restarts".
      final store = InMemoryAuthSessionStore();
      final repo = MockAuthRepository(session: store);

      expect(await repo.currentUser(), isNull);

      final user = await repo.verifyOtp(phone: '81234567890', code: '123456');

      // A fresh repository backed by the same store sees the saved session.
      final restored = MockAuthRepository(session: store);
      expect(await restored.currentUser(), user);
    });

    test('signOut clears the persisted session', () async {
      final store = InMemoryAuthSessionStore();
      final repo = MockAuthRepository(session: store);
      await repo.verifyOtp(phone: '81234567890', code: '123456');

      await repo.signOut();

      expect(await repo.currentUser(), isNull);
    });
  });
}
