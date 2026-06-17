import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists the app-lock PIN (stored as a hash, never plaintext) and the
/// biometric-unlock preference. The bloc hashes the PIN before saving/comparing.
abstract class PinStore {
  Future<String?> readHash();
  Future<void> saveHash(String hash);
  Future<void> clear();

  Future<bool> readBiometricEnabled();
  Future<void> saveBiometricEnabled(bool enabled);
}

/// Default, non-persistent store (tests / fallback).
class InMemoryPinStore implements PinStore {
  String? _hash;
  bool _biometric = false;

  @override
  Future<String?> readHash() async => _hash;

  @override
  Future<void> saveHash(String hash) async => _hash = hash;

  @override
  Future<void> clear() async {
    _hash = null;
    _biometric = false;
  }

  @override
  Future<bool> readBiometricEnabled() async => _biometric;

  @override
  Future<void> saveBiometricEnabled(bool enabled) async => _biometric = enabled;
}

/// Persists in the platform secure store.
class SecurePinStore implements PinStore {
  static const _pinKey = 'app_pin_hash';
  static const _bioKey = 'app_biometric_enabled';

  final FlutterSecureStorage _storage;

  const SecurePinStore([this._storage = const FlutterSecureStorage()]);

  @override
  Future<String?> readHash() => _storage.read(key: _pinKey);

  @override
  Future<void> saveHash(String hash) => _storage.write(key: _pinKey, value: hash);

  @override
  Future<void> clear() async {
    await _storage.delete(key: _pinKey);
    await _storage.delete(key: _bioKey);
  }

  @override
  Future<bool> readBiometricEnabled() async =>
      (await _storage.read(key: _bioKey)) == 'true';

  @override
  Future<void> saveBiometricEnabled(bool enabled) =>
      _storage.write(key: _bioKey, value: enabled.toString());
}
