import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Stores the API access token (JWT). The API client reads it to authorize
/// requests; the auth repository writes it on login and clears it on sign-out.
abstract class AuthTokenStore {
  Future<String?> read();
  Future<void> save(String token);
  Future<void> clear();
}

/// Default, non-persistent store (tests / fallback).
class InMemoryAuthTokenStore implements AuthTokenStore {
  String? _token;

  @override
  Future<String?> read() async => _token;

  @override
  Future<void> save(String token) async => _token = token;

  @override
  Future<void> clear() async => _token = null;
}

/// Persists the token in the platform secure store.
class SecureAuthTokenStore implements AuthTokenStore {
  static const _key = 'api_token';

  final FlutterSecureStorage _storage;

  const SecureAuthTokenStore([this._storage = const FlutterSecureStorage()]);

  @override
  Future<String?> read() => _storage.read(key: _key);

  @override
  Future<void> save(String token) => _storage.write(key: _key, value: token);

  @override
  Future<void> clear() => _storage.delete(key: _key);
}
