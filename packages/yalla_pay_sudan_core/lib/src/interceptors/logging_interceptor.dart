import 'dart:developer' as developer;

import 'package:dio/dio.dart';

/// Development-only logging of requests and responses.
///
/// Added only when `YallaPayConfig.enableLogging` is `true` (off by default).
/// It logs the method, path, request body, response status and error
/// response body. It never logs headers, so the `Authorization` token is
/// never written. Bodies can contain amounts, customer references and
/// redirect URLs, so do not enable it in production.
class YallaPayLoggingInterceptor extends Interceptor {
  /// Where log lines go. Defaults to `dart:developer` `log` under the name
  /// `YallaPaySudan`.
  final void Function(String message) log;

  /// Creates the interceptor, optionally with a custom [log] sink.
  YallaPayLoggingInterceptor({void Function(String message)? log})
    : log = log ?? _developerLog;

  static void _developerLog(String message) =>
      developer.log(message, name: 'YallaPaySudan');

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    log('REQUEST[${options.method}] => ${options.path}\nBody: ${options.data}');
    handler.next(options);
  }

  @override
  void onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) {
    log('RESPONSE[${response.statusCode}] => ${response.requestOptions.path}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    log(
      'ERROR[${err.response?.statusCode ?? err.type.name}] => '
      '${err.requestOptions.path}\nBody: ${err.response?.data}',
    );
    handler.next(err);
  }
}
