import 'package:dio/dio.dart';

import 'auth_token_store.dart';

/// Thin wrapper over Dio that injects the bearer token, unwraps the API's
/// `{"data": ...}` envelope, and surfaces non-2xx responses as thrown
/// [DioException]s (which blocs catch and translate to `AppFailure`).
class ApiClient {
  final Dio _dio;

  ApiClient({required String baseUrl, required AuthTokenStore tokenStore})
      : _dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
          contentType: 'application/json',
        )) {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await tokenStore.read();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
    ));
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) async {
    final res = await _dio.get(path, queryParameters: query);
    return _unwrap(res);
  }

  Future<dynamic> post(String path, {Object? body}) async {
    final res = await _dio.post(path, data: body);
    return _unwrap(res);
  }

  dynamic _unwrap(Response<dynamic> res) {
    final data = res.data;
    if (data is Map && data.containsKey('data')) {
      return data['data'];
    }
    return data;
  }
}
