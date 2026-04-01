import 'dart:developer' as developer;

import 'package:dio/dio.dart';

/// Optional debug logging interceptor that masks sensitive headers.
class YallaPayLoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    developer.log(
      'REQUEST[${options.method}] => ${options.path}\n'
      'Body: ${options.data}',
      name: 'YallaPaySudan',
    );
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    developer.log(
      'RESPONSE[${response.statusCode}] => '
      '${response.requestOptions.path}',
      name: 'YallaPaySudan',
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    developer.log(
      'ERROR[${err.response?.statusCode}] => '
      '${err.requestOptions.path}\n'
      'Body: ${err.response?.data}',
      name: 'YallaPaySudan',
    );
    handler.next(err);
  }
}
