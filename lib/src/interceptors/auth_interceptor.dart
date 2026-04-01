import 'package:dio/dio.dart';

/// Injects Bearer token authentication and JSON content headers
/// into every request.
class AuthInterceptor extends Interceptor {
  final String apiKey;

  AuthInterceptor(this.apiKey);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers['Authorization'] = 'Bearer $apiKey';
    options.headers['Accept'] = 'application/json';
    options.headers['Content-Type'] = 'application/json';
    handler.next(options);
  }
}
