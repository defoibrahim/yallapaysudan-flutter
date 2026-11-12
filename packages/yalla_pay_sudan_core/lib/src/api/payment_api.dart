import 'dart:convert';

import 'package:dio/dio.dart';

import '../exceptions/yalla_pay_exception.dart';
import '../internal/json.dart';
import '../models/payment_request.dart';
import '../models/payment_response.dart';
import '../models/payment_status_response.dart';
import '../models/subscription_request.dart';
import 'api_constants.dart';

/// HTTP layer for the YallaPaySudan API. Every failure surfaces as a
/// [YallaPayException].
class PaymentApi {
  final Dio _dio;

  /// Creates a [PaymentApi] on top of a configured [Dio].
  PaymentApi(this._dio);

  /// Creates a one-time payment link.
  Future<PaymentResponse> generatePaymentLink(PaymentRequest request) async {
    final data = await _post(ApiConstants.generatePaymentLink, request.toJson());
    return _parsePaymentResponse(data);
  }

  /// Creates a subscription payment link.
  Future<PaymentResponse> generateSubscriptionLink(
    SubscriptionRequest request,
  ) async {
    final data = await _post(
      ApiConstants.generateSubscriptionPaymentLink,
      request.toJson(),
    );
    return _parsePaymentResponse(data);
  }

  /// Checks the status of a payment. [transactionDate] is `YYYY-MM-DD`.
  Future<PaymentStatusResponse> getPaymentStatus({
    required String clientReferenceId,
    required String transactionDate,
  }) async {
    final data = await _post(ApiConstants.getPaymentStatus, {
      'clientReferenceId': clientReferenceId,
      'transactionDate': transactionDate,
    });
    // Errors come back as a `responseCode`/`responseMessage` envelope.
    final code = readString(data, 'responseCode');
    if (code != null && code != '0') {
      throw _paymentException(
        code: code,
        message: readString(data, 'responseMessage'),
        statusCode: null,
        body: data,
      );
    }
    return PaymentStatusResponse.fromJson(data);
  }

  PaymentResponse _parsePaymentResponse(Map<String, dynamic> data) {
    final response = PaymentResponse.fromJson(data);
    if (!response.isSuccess) {
      throw _paymentException(
        code: response.responseCode.isEmpty ? '-1' : response.responseCode,
        message: response.responseMessage,
        statusCode: null,
        body: data,
      );
    }
    final uri = Uri.tryParse(response.paymentUrl);
    if (uri == null || !uri.isScheme('https') || uri.host.isEmpty) {
      throw InvalidResponseException(
        'Success response without a valid https paymentUrl.',
        rawResponse: data,
      );
    }
    return response;
  }

  /// POSTs [payload] and returns the decoded JSON object.
  Future<Map<String, dynamic>> _post(
    String endpoint,
    Map<String, dynamic> payload,
  ) async {
    final Response<Object?> response;
    try {
      response = await _dio.post<Object?>(endpoint, data: payload);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
    final body = _decodeObject(response.data);
    if (body == null) {
      throw InvalidResponseException(
        'Expected a JSON object from YallaPaySudan.',
        rawResponse: response.data,
      );
    }
    return body;
  }

  YallaPayException _mapDioException(DioException e) {
    final statusCode = e.response?.statusCode;
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return NetworkException(
          message: 'Request to YallaPaySudan timed out (${e.type.name}).',
          isTimeout: true,
          dioException: e,
        );
      case DioExceptionType.badResponse:
        final body = _decodeObject(e.response?.data);
        try {
          return _paymentException(
            code: (body == null ? null : readString(body, 'responseCode')) ??
                '$statusCode',
            message: body == null ? null : readString(body, 'responseMessage'),
            statusCode: statusCode,
            body: body,
          );
        } on InvalidResponseException {
          return _paymentException(
            code: '$statusCode',
            message: null,
            statusCode: statusCode,
            body: body,
          );
        }
      default:
        // connectionError, badCertificate, cancel, unknown, and any type a
        // future Dio version adds.
        return NetworkException(
          message: 'Request to YallaPaySudan failed: ${e.message ?? e.type.name}',
          dioException: e,
        );
    }
  }

  PaymentException _paymentException({
    required String code,
    required String? message,
    required int? statusCode,
    required Map<String, dynamic>? body,
  }) {
    final text = (message == null || message.isEmpty)
        ? 'YallaPaySudan error ${statusCode ?? code}.'
        : message;
    if (_isDuplicateReference(text)) {
      return DuplicateReferenceException(
        message: text,
        responseCode: code,
        statusCode: statusCode,
        rawResponse: body,
      );
    }
    return PaymentException(
      message: text,
      responseCode: code,
      statusCode: statusCode,
      rawResponse: body,
    );
  }

  static bool _isDuplicateReference(String message) {
    final m = message.toLowerCase();
    return m.contains('duplicate') && m.contains('reference');
  }

  /// Returns the body as a JSON object, decoding a JSON string if the server
  /// did not send a JSON content type. `null` if it is not a JSON object.
  static Map<String, dynamic>? _decodeObject(Object? data) {
    if (data is Map<String, dynamic>) return data;
    if (data is String && data.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(data);
        if (decoded is Map<String, dynamic>) return decoded;
      } on FormatException {
        return null;
      }
    }
    return null;
  }
}
