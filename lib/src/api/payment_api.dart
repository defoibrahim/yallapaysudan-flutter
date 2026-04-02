import 'package:dio/dio.dart';

import '../exceptions/yalla_pay_exception.dart';
import '../models/payment_request.dart';
import '../models/payment_response.dart';
import '../models/payment_status_response.dart';
import '../models/subscription_request.dart';
import 'api_constants.dart';

/// Handles HTTP communication with the YallaPaySudan API.
class PaymentApi {
  final Dio _dio;

  PaymentApi(this._dio);

  /// Generates a one-time payment link.
  Future<PaymentResponse> generatePaymentLink(PaymentRequest request) async {
    final data = await _post(ApiConstants.generatePaymentLink, request.toJson());
    return _parsePaymentResponse(data);
  }

  /// Generates a subscription payment link.
  Future<PaymentResponse> generateSubscriptionLink(
    SubscriptionRequest request,
  ) async {
    final data = await _post(
      ApiConstants.generateSubscriptionPaymentLink,
      request.toJson(),
    );
    return _parsePaymentResponse(data);
  }

  /// Checks the status of a payment.
  Future<PaymentStatusResponse> getPaymentStatus({
    required String clientReferenceId,
    required String transactionDate,
  }) async {
    final data = await _post(
      ApiConstants.getPaymentStatus,
      {
        'clientReferenceId': clientReferenceId,
        'transactionDate': transactionDate,
      },
    );
    return PaymentStatusResponse.fromJson(data);
  }

  /// Parses a payment response and throws if the API returned an error.
  PaymentResponse _parsePaymentResponse(Map<String, dynamic> data) {
    final response = PaymentResponse.fromJson(data);
    if (!response.isSuccess) {
      throw PaymentException(
        message: response.responseMessage,
        responseCode: response.responseCode,
        rawResponse: data,
      );
    }
    return response;
  }

  /// Makes a POST request and returns the parsed JSON body.
  /// Handles Dio errors and maps them to package exceptions.
  Future<Map<String, dynamic>> _post(
    String endpoint,
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        endpoint,
        data: payload,
      );

      final data = response.data;
      if (data == null) {
        throw const PaymentException(
          message: 'Invalid response: empty body received from YallaPaySudan.',
          responseCode: '-1',
        );
      }

      return data;
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  /// Maps a [DioException] to the appropriate package exception.
  Never _mapDioException(DioException e) {
    final responseData = e.response?.data;
    if (responseData is Map<String, dynamic>) {
      final code =
          responseData['responseCode'] as String? ?? '${e.response?.statusCode}';
      final message = responseData['responseMessage'] as String? ??
          'HTTP ${e.response?.statusCode} error from YallaPaySudan.';
      throw PaymentException(
        message: message,
        responseCode: code,
        rawResponse: responseData,
      );
    }

    final statusCode = e.response?.statusCode;
    if (statusCode != null) {
      throw PaymentException(
        message: 'HTTP $statusCode error from YallaPaySudan.',
        responseCode: '$statusCode',
      );
    }

    throw NetworkException(
      message: 'HTTP request to YallaPaySudan failed: ${e.message}',
      dioException: e,
    );
  }
}
