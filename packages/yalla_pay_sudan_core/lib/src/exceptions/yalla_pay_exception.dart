import 'package:dio/dio.dart';

/// Base class for every error this package throws while talking to
/// YallaPaySudan or verifying a webhook.
///
/// The class is `sealed`, so a `switch` over a [YallaPayException] is checked
/// for exhaustiveness by the compiler:
///
/// ```dart
/// try {
///   await client.createPayment(request);
/// } on YallaPayException catch (e) {
///   switch (e) {
///     case DuplicateReferenceException():
///       // The reference was already used: look the payment up instead.
///     case PaymentException():
///       // The gateway rejected the request.
///     case NetworkException(isTimeout: true):
///       // The request may have reached the gateway: check its status.
///     case NetworkException():
///       // Nothing reached the gateway.
///     case InvalidResponseException():
///       // The gateway answered with something this package cannot read.
///     case InvalidSignatureException():
///       // Webhook signature or timestamp check failed.
///   }
/// }
/// ```
///
/// Invalid arguments (for example an amount below the gateway minimum) are
/// programming errors and throw [ArgumentError] instead.
sealed class YallaPayException implements Exception {
  /// A human-readable description of the error.
  final String message;

  /// Creates an exception with the given [message].
  const YallaPayException(this.message);

  @override
  String toString() => '$runtimeType: $message';
}

/// The gateway answered, but rejected the request: a non-zero
/// `responseCode`, or an HTTP error status.
class PaymentException extends YallaPayException {
  /// The gateway's `responseCode` ("0" means success), or the HTTP status
  /// code as a string when the body had no `responseCode`.
  final String responseCode;

  /// The HTTP status code, when the error came with an HTTP error status.
  final int? statusCode;

  /// The decoded response body, when it was a JSON object.
  final Map<String, dynamic>? rawResponse;

  /// Creates a [PaymentException].
  const PaymentException({
    required String message,
    required this.responseCode,
    this.statusCode,
    this.rawResponse,
  }) : super(message);
}

/// The `clientReferenceId` was already used for another payment.
///
/// Reference IDs are the gateway's idempotency key: a payment can be created
/// only once per reference. This usually means an earlier request for the
/// same order already succeeded (for example one that timed out on the way
/// back). Look it up with `YallaPayClient.getPaymentStatus` rather than
/// creating a new reference for the same order.
///
/// The gateway does not document a dedicated code for this case, so it is
/// recognised from the error message ("duplicate ... reference").
class DuplicateReferenceException extends PaymentException {
  /// Creates a [DuplicateReferenceException].
  const DuplicateReferenceException({
    required super.message,
    required super.responseCode,
    super.statusCode,
    super.rawResponse,
  });
}

/// The request did not complete: no connection, DNS failure, TLS error,
/// timeout or cancellation.
///
/// When [isTimeout] is `true` the request may still have reached the gateway
/// and a payment link may exist. Before retrying `createPayment` with a new
/// `clientReferenceId`, check the original one with
/// `YallaPayClient.getPaymentStatus`; retrying with the same reference fails
/// with [DuplicateReferenceException] if the first attempt went through.
class NetworkException extends YallaPayException {
  /// Whether the request timed out (connect, send or receive timeout).
  final bool isTimeout;

  /// The underlying Dio exception, if available.
  final DioException? dioException;

  /// Creates a [NetworkException].
  const NetworkException({
    required String message,
    this.isTimeout = false,
    this.dioException,
  }) : super(message);
}

/// The gateway (or a webhook with a valid signature) returned data this
/// package cannot read: not JSON, a missing required field, or a field of
/// the wrong type.
class InvalidResponseException extends YallaPayException {
  /// The response body as received, when available.
  final Object? rawResponse;

  /// Creates an [InvalidResponseException].
  const InvalidResponseException(super.message, {this.rawResponse});
}

/// A webhook failed verification: the signature does not match, or the
/// timestamp is missing, malformed or outside the allowed window.
///
/// Answer the webhook request with HTTP 401 and do not act on its content.
class InvalidSignatureException extends YallaPayException {
  /// Creates an [InvalidSignatureException].
  const InvalidSignatureException([
    super.message = 'Webhook signature verification failed.',
  ]);
}
