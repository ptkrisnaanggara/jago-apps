import 'package:local_auth/local_auth.dart';

/// Device biometric authentication, behind an interface so the SecurityBloc is
/// testable (tests inject a fake; `main` wires [LocalAuthBiometric]).
abstract class BiometricAuth {
  /// Whether the device has biometrics enrolled and usable.
  Future<bool> isAvailable();

  /// Prompt for a biometric check; returns true on success.
  Future<bool> authenticate(String reason);
}

/// Real implementation backed by `local_auth`.
class LocalAuthBiometric implements BiometricAuth {
  final LocalAuthentication _auth;

  LocalAuthBiometric([LocalAuthentication? auth])
      : _auth = auth ?? LocalAuthentication();

  @override
  Future<bool> isAvailable() async {
    try {
      return await _auth.isDeviceSupported() &&
          await _auth.canCheckBiometrics;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> authenticate(String reason) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }
}

/// No-op implementation (default / tests): biometrics unavailable.
class NoBiometric implements BiometricAuth {
  const NoBiometric();

  @override
  Future<bool> isAvailable() async => false;

  @override
  Future<bool> authenticate(String reason) async => false;
}
