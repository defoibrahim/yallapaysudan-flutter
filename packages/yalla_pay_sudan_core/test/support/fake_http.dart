import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// Answers requests from a handler instead of the network, so tests run the
/// real Dio pipeline (JSON decoding, status validation, error types).
class FakeAdapter implements HttpClientAdapter {
  FakeAdapter(this.handler);

  /// Returns the response for a request, or throws a [DioException].
  FutureOr<ResponseBody> Function(RequestOptions options) handler;

  /// Every request seen, in order.
  final List<RequestOptions> requests = [];

  /// Whether [close] was called.
  bool closed = false;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return handler(options);
  }

  @override
  void close({bool force = false}) => closed = true;
}

/// A JSON response.
ResponseBody jsonResponse(Object? body, {int status = 200}) => ResponseBody.fromString(
  jsonEncode(body),
  status,
  headers: {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  },
);

/// A non-JSON response.
ResponseBody textResponse(
  String body, {
  int status = 200,
  String contentType = 'text/plain',
}) => ResponseBody.fromString(
  body,
  status,
  headers: {
    Headers.contentTypeHeader: [contentType],
  },
);

/// A Dio wired to [adapter].
Dio fakeDio(FakeAdapter adapter) =>
    Dio(BaseOptions(baseUrl: 'https://gateway.example/api/v1'))
      ..httpClientAdapter = adapter;

/// A successful payment-link response.
const successBody = {
  'responseCode': '0',
  'responseMessage': 'Success',
  'currentDate': '2025-06-22',
  'currentTime': '13:25:20',
  'paymentUrl': 'https://gateway.yallapaysudan.com/checkout/web/test-id',
};
