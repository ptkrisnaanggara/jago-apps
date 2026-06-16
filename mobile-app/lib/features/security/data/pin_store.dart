import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists the app-lock PIN (stored as a hash, never plaintext). The bloc
/// hashes the PIN before saving / comparing.
abstract class PinStore {
  Future<String?> readHash();
  Future<void> saveHash(String hash);
  Future<void> clear();
}

/// Default, non-persistent store (tests / fallback).
class InMemoryPinStore implements PinStore {
  String? _hash;

  @override
  Future<String?> readHash() async => _hash;

  @override
  Future<void> saveHash(String hash) async => _hash = hash;

  @override
  Future<void> clear() async => _hash = null;
}

/// Persists the PIN hash in the platform secure store.
class SecurePinStore implements PinStore {
  static const _key = 'app_pin_hash';

  final FlutterSecureStorage _storage;

  const SecurePinStore([this._storage = const FlutterSecureStorage()]);

  @override
  Future<String?> readHash() => _storage.read(key: _key);

  @override
  Future<void> saveHash(String hash) => _storage.write(key: _key, value: hash);

  @override
  Future<void> clear() => _storage.delete(key: _key);
}
