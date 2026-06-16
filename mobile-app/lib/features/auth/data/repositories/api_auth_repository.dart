import 'package:jago/core/network/api_client.dart';
import 'package:jago/core/network/auth_token_store.dart';

import '../models/auth_user.dart';
import 'auth_repository.dart';

/// Backend-backed [AuthRepository] (phone + OTP → JWT). The token is persisted
/// via [AuthTokenStore] so the API client can authorize subsequent requests.
class ApiAuthRepository implements AuthRepository {
  final ApiClient _api;
  final AuthTokenStore _tokens;

  ApiAuthRepository({required ApiClient api, required AuthTokenStore tokens})
      : _api = api,
        _tokens = tokens;

  @override
  Future<AuthUser?> currentUser() async {
    final token = await _tokens.read();
    if (token == null || token.isEmpty) return null;
    try {
      final data = await _api.get('/me');
      return _userFromJson(data as Map<String, dynamic>);
    } catch (_) {
      // Token missing/expired/invalid → treat as signed out.
      await _tokens.clear();
      return null;
    }
  }

  @override
  Future<void> requestOtp(String phone) async {
    await _api.post('/auth/otp/request', body: {'phone': phone});
  }

  @override
  Future<AuthUser> verifyOtp({
    required String phone,
    required String code,
    String? name,
  }) async {
    final data = await _api.post('/auth/otp/verify', body: {
      'phone': phone,
      'code': code,
      if (name != null && name.isNotEmpty) 'name': name,
    }) as Map<String, dynamic>;

    await _tokens.save(data['token'] as String);
    return _userFromJson(data['user'] as Map<String, dynamic>);
  }

  @override
  Future<void> signOut() async {
    await _tokens.clear();
  }

  AuthUser _userFromJson(Map<String, dynamic> json) => AuthUser(
        id: json['id'] as String,
        name: json['name'] as String,
        phone: json['phone'] as String,
      );
}
