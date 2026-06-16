import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/auth_user.dart';

/// Persists the signed-in session. Abstracted so the repository depends on a
/// contract — the secure-storage impl is wired in `main.dart`, while tests use
/// the in-memory impl (no platform plugin required).
abstract class AuthSessionStore {
  Future<AuthUser?> read();
  Future<void> save(AuthUser user);
  Future<void> clear();
}

/// Default, non-persistent store (used by tests and as a safe fallback).
class InMemoryAuthSessionStore implements AuthSessionStore {
  AuthUser? _user;

  @override
  Future<AuthUser?> read() async => _user;

  @override
  Future<void> save(AuthUser user) async => _user = user;

  @override
  Future<void> clear() async => _user = null;
}

/// Persists the session in the platform secure store so login survives
/// restarts. In a real app this would hold an opaque auth token.
class SecureAuthSessionStore implements AuthSessionStore {
  static const _key = 'auth_session';

  final FlutterSecureStorage _storage;

  const SecureAuthSessionStore([
    this._storage = const FlutterSecureStorage(),
  ]);

  @override
  Future<AuthUser?> read() async {
    final raw = await _storage.read(key: _key);
    if (raw == null) return null;
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return AuthUser(
      id: json['id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String,
    );
  }

  @override
  Future<void> save(AuthUser user) async {
    final raw = jsonEncode({
      'id': user.id,
      'name': user.name,
      'phone': user.phone,
    });
    await _storage.write(key: _key, value: raw);
  }

  @override
  Future<void> clear() async => _storage.delete(key: _key);
}
