import 'package:dio/dio.dart';

import '../api/payment_api.dart';
import '../exceptions/yalla_pay_exception.dart';
import '../interceptors/auth_interceptor.dart';
import '../interceptors/logging_interceptor.dart';
import '../models/payment_request.dart';
import '../models/payment_response.dart';
import '../models/payment_status_response.dart';
import '../models/subscription_request.dart';
import '../models/webhook_payload.dart';
import '../webhook/webhook_verifier.dart';
import 'yalla_pay_config.dart';

/// Main client for interacting with the YallaPaySudan payment gateway.
///
/// ```dart
/// final client = YallaPayClient(
///   YallaPayConfig(apiKey: 'your-api-key'),
/// );
///
/// final response = await client.createPayment(
///   PaymentRequest(
///     amount: 5000,
///     clientReferenceId: 'order-123',
///   ),
/// );
/// ```
class YallaPayClient {
  final YallaPayConfig config;
  final Dio _dio;
  late final PaymentApi _paymentApi;
  final WebhookVerifier? _webhookVerifier;

  /// Creates a new [YallaPayClient] with the given [config].
  YallaPayClient(YallaPayConfig config)
      : this.withDio(config, _createDio(config));

  /// Creates a [YallaPayClient] with a pre-configured [Dio] instance.
  ///
  /// Useful for testing with mocked HTTP clients.
  YallaPayClient.withDio(this.config, this._dio)
      : _webhookVerifier = config.webhookSecret != null
            ? WebhookVerifier(
                secret: config.webhookSecret!,
                timestampTolerance: config.webhookTimestampTolerance,
              )
            : null {
    _paymentApi = PaymentApi(_dio);
  }

  /// Generates a one-time payment link.
  ///
  /// Throws [PaymentException] if the API returns an error.
  /// Throws [NetworkException] on connection failures.
  /// Throws [ArgumentError] if the request fields are invalid.
  Future<PaymentResponse> createPayment(PaymentRequest request) async {
    request.validate();
    final response = await _paymentApi.generatePaymentLink(request);
    return response.copyWith(
      successRedirectUrl: request.paymentSuccessfulRedirectUrl,
      failedRedirectUrl: request.paymentFailedRedirectUrl,
    );
  }

  /// Generates a subscription payment link.
  ///
  /// Throws [PaymentException] if the API returns an error.
  /// Throws [NetworkException] on connection failures.
  /// Throws [ArgumentError] if the request fields are invalid.
  Future<PaymentResponse> createSubscription(
    SubscriptionRequest request,
  ) async {
    request.validate();
    final response = await _paymentApi.generateSubscriptionLink(request);
    return response.copyWith(
      successRedirectUrl: request.paymentSuccessfulRedirectUrl,
      failedRedirectUrl: request.paymentFailedRedirectUrl,
    );
  }

  /// Checks the status of a payment.
  ///
  /// [clientReferenceId] is the unique ID you passed when creating the payment.
  /// [transactionDate] is the date the payment was initiated (YYYY-MM-DD).
  ///
  /// Throws [PaymentException] if the API returns an error.
  /// Throws [NetworkException] on connection failures.
  Future<PaymentStatusResponse> getPaymentStatus({
    required String clientReferenceId,
    required String transactionDate,
  }) async {
    return _paymentApi.getPaymentStatus(
      clientReferenceId: clientReferenceId,
      transactionDate: transactionDate,
    );
  }

  /// Verifies a webhook signature and parses the payload.
  ///
  /// Requires [YallaPayConfig.webhookSecret] to be set.
  ///
  /// Throws [InvalidSignatureException] if the signature is invalid
  /// or the timestamp is expired.
  /// Throws [StateError] if no webhook secret is configured.
  WebhookPayload verifyWebhook({
    required String signature,
    required String timestamp,
    required String rawBody,
  }) {
    if (_webhookVerifier == null) {
      throw StateError(
        'Webhook secret not configured. '
        'Set webhookSecret in YallaPayConfig to use webhook verification.',
      );
    }
    return _webhookVerifier.verify(
      signature: signature,
      timestamp: timestamp,
      rawBody: rawBody,
    );
  }

  /// Closes the underlying HTTP client and releases resources.
  void dispose() {
    _dio.close();
  }

  static Dio _createDio(YallaPayConfig config) {
    final dio = Dio(
      BaseOptions(
        baseUrl: config.baseUrl,
        connectTimeout: config.connectTimeout,
        receiveTimeout: config.receiveTimeout,
      ),
    );

    dio.interceptors.add(AuthInterceptor(config.apiKey));

    if (config.enableLogging) {
      dio.interceptors.add(YallaPayLoggingInterceptor());
    }

    return dio;
  }
}
