import '../models/auth_user.dart';
import '../sources/auth_session_store.dart';

/// Authentication contract. The UI/BLoC depend on this, never the mock.
/// A real implementation would call an API and persist the token in
/// secure storage (see PRD §5 "Networking & data").
abstract class AuthRepository {
  /// Returns the signed-in user if a session exists, otherwise `null`.
  Future<AuthUser?> currentUser();

  /// Triggers an OTP to be sent to [phone].
  Future<void> requestOtp(String phone);

  /// Verifies [code] for [phone] and returns the authenticated user.
  /// [name] is provided during sign-up so the new account can be created.
  Future<AuthUser> verifyOtp({
    required String phone,
    required String code,
    String? name,
  });

  Future<void> signOut();
}

/// Temporary mock. Accepts the demo OTP `123456` and persists the resulting
/// session via [AuthSessionStore] so login survives restarts. Defaults to an
/// in-memory store (tests); `main.dart` injects the secure-storage impl.
class MockAuthRepository implements AuthRepository {
  static const _latency = Duration(milliseconds: 600);
  static const demoOtp = '123456';

  final AuthSessionStore _session;

  MockAuthRepository({AuthSessionStore? session})
      : _session = session ?? InMemoryAuthSessionStore();

  @override
  Future<AuthUser?> currentUser() async {
    await Future<void>.delayed(_latency);
    return _session.read();
  }

  @override
  Future<void> requestOtp(String phone) async {
    await Future<void>.delayed(_latency);
  }

  @override
  Future<AuthUser> verifyOtp({
    required String phone,
    required String code,
    String? name,
  }) async {
    await Future<void>.delayed(_latency);
    if (code != demoOtp) {
      throw Exception('Kode OTP salah');
    }
    final user = AuthUser(
      id: 'u1',
      name: (name == null || name.isEmpty) ? 'Nasabah Jago' : name,
      phone: phone,
    );
    await _session.save(user);
    return user;
  }

  @override
  Future<void> signOut() async {
    await Future<void>.delayed(_latency);
    await _session.clear();
  }
}
