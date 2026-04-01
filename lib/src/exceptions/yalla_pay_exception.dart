import 'package:dio/dio.dart';

/// Base exception for all YallaPaySudan errors.
///
/// Sealed so consumers can use exhaustive `switch` matching.
sealed class YallaPayException implements Exception {
  final String message;

  const YallaPayException(this.message);

  @override
  String toString() => '$runtimeType: $message';
}

/// Thrown when the YallaPaySudan API returns a non-success response code.
class PaymentException extends YallaPayException {
  /// The API response code (anything other than "0" indicates an error).
  final String responseCode;

  /// The full raw response from the API, if available.
  final Map<String, dynamic>? rawResponse;

  const PaymentException({
    required String message,
    required this.responseCode,
    this.rawResponse,
  }) : super(message);
}

/// Thrown when webhook signature verification fails.
class InvalidSignatureException extends YallaPayException {
  const InvalidSignatureException([
    super.message = 'Webhook signature verification failed.',
  ]);
}

/// Thrown when a network error occurs during an API request.
class NetworkException extends YallaPayException {
  /// The underlying Dio exception, if available.
  final DioException? dioException;

  const NetworkException({
    required String message,
    this.dioException,
  }) : super(message);
}
