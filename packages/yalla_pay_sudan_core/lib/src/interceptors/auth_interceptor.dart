import 'package:dio/dio.dart';

/// Adds the `Authorization: Bearer <apiKey>` header and JSON content headers
/// to every request.
class AuthInterceptor extends Interceptor {
  /// The merchant auth token.
  final String apiKey;

  /// Creates an [AuthInterceptor] for [apiKey].
  AuthInterceptor(this.apiKey);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers['Authorization'] = 'Bearer $apiKey';
    options.headers['Accept'] = 'application/json';
    options.headers['Content-Type'] = 'application/json';
    handler.next(options);
  }
}
