import 'package:dio/dio.dart';

import '../exceptions/yalla_pay_exception.dart';
import '../models/payment_request.dart';
import '../models/payment_response.dart';
import '../models/subscription_request.dart';
import 'api_constants.dart';

/// Handles HTTP communication with the YallaPaySudan API.
class PaymentApi {
  final Dio _dio;

  PaymentApi(this._dio);

  /// Generates a one-time payment link.
  Future<PaymentResponse> generatePaymentLink(PaymentRequest request) async {
    return _post(ApiConstants.generatePaymentLink, request.toJson());
  }

  /// Generates a subscription payment link.
  Future<PaymentResponse> generateSubscriptionLink(
    SubscriptionRequest request,
  ) async {
    return _post(
      ApiConstants.generateSubscriptionPaymentLink,
      request.toJson(),
    );
  }

  Future<PaymentResponse> _post(
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

      final paymentResponse = PaymentResponse.fromJson(data);

      if (!paymentResponse.isSuccess) {
        throw PaymentException(
          message: paymentResponse.responseMessage,
          responseCode: paymentResponse.responseCode,
          rawResponse: data,
        );
      }

      return paymentResponse;
    } on DioException catch (e) {
      // If the server returned an HTTP error with a JSON body, extract it.
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
}
