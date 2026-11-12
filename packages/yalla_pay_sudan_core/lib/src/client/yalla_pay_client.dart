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

/// Client for the YallaPaySudan gateway API. **Server-side only.**
///
/// It authenticates with the merchant auth token, which must stay on your
/// server. The usual flow:
///
/// 1. Your app asks your backend to start a checkout for an order.
/// 2. The backend calls [createPayment] and returns only
///    [PaymentResponse.paymentUrl] (and the redirect URLs) to the app.
/// 3. The app opens the URL, for example with `YallaPayCheckoutWebView`
///    from the `yalla_pay_sudan` Flutter package.
/// 4. The backend learns the outcome from the webhook ([verifyWebhook]) or
///    [getPaymentStatus], and the app asks the backend for the order state.
///
/// ```dart
/// final client = YallaPayClient(
///   YallaPayConfig.sandbox(apiKey: Platform.environment['YALLAPAY_API_KEY']!),
/// );
///
/// final response = await client.createPayment(
///   PaymentRequest(amount: 5000, clientReferenceId: 'order-123'),
/// );
/// ```
class YallaPayClient {
  /// The configuration this client was created with.
  final YallaPayConfig config;

  final Dio _dio;
  final PaymentApi _paymentApi;
  final WebhookVerifier? _webhookVerifier;

  /// Creates a client for [config].
  ///
  /// Throws [ArgumentError] if `config.apiKey` is empty.
  YallaPayClient(YallaPayConfig config)
    : this.withDio(config, _createDio(config));

  /// Creates a client that sends requests through [dio], for example a
  /// mocked or specially configured instance. The auth and logging
  /// interceptors are not added to [dio].
  YallaPayClient.withDio(this.config, this._dio)
    : _paymentApi = PaymentApi(_dio),
      _webhookVerifier = config.webhookSecret == null
          ? null
          : WebhookVerifier(
              secret: config.webhookSecret!,
              timestampTolerance: config.webhookTimestampTolerance,
            ) {
    if (config.apiKey.isEmpty) {
      throw ArgumentError.value(config.apiKey, 'config.apiKey', 'Is empty');
    }
  }

  /// Creates a one-time payment link.
  ///
  /// Not retried automatically. On a [NetworkException] with
  /// `isTimeout == true` the payment may have been created: check it with
  /// [getPaymentStatus] using the same reference before trying again.
  ///
  /// Throws [ArgumentError] for invalid fields, [DuplicateReferenceException]
  /// if the reference was already used, [PaymentException] if the gateway
  /// rejects the request, [NetworkException] if it cannot be reached, and
  /// [InvalidResponseException] for an unreadable answer.
  Future<PaymentResponse> createPayment(PaymentRequest request) async {
    request.validate();
    final response = await _paymentApi.generatePaymentLink(request);
    return response.copyWith(
      successRedirectUrl: request.paymentSuccessfulRedirectUrl,
      failedRedirectUrl: request.paymentFailedRedirectUrl,
    );
  }

  /// Creates a subscription payment link. Errors are the same as for
  /// [createPayment].
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
  /// [clientReferenceId] is the reference you created the payment with, and
  /// [transactionDate] the day it was created; only its year, month and day
  /// are used. Network errors are retried up to `config.statusRetries` times.
  ///
  /// Throws [PaymentException] if the gateway returns an error,
  /// [NetworkException] if it cannot be reached after the retries, and
  /// [InvalidResponseException] for an unreadable answer.
  Future<PaymentStatusResponse> getPaymentStatus({
    required String clientReferenceId,
    required DateTime transactionDate,
  }) async {
    if (clientReferenceId.trim().isEmpty) {
      throw ArgumentError.value(
        clientReferenceId,
        'clientReferenceId',
        'Must not be empty',
      );
    }
    final date = formatTransactionDate(transactionDate);
    var delay = config.retryDelay;
    for (var attempt = 0; ; attempt++) {
      try {
        return await _paymentApi.getPaymentStatus(
          clientReferenceId: clientReferenceId,
          transactionDate: date,
        );
      } on NetworkException {
        if (attempt >= config.statusRetries) rethrow;
        await Future<void>.delayed(delay);
        delay *= 2;
      }
    }
  }

  /// Verifies a webhook whose body you have as an undecoded string. See
  /// [WebhookVerifier] for what is checked.
  ///
  /// Throws [StateError] if `config.webhookSecret` is not set,
  /// [InvalidSignatureException] if verification fails, and
  /// [InvalidResponseException] if a correctly signed body is not a valid
  /// payload.
  WebhookPayload verifyWebhook({
    required String signature,
    required String timestamp,
    required String rawBody,
  }) => _verifier.verify(
    signature: signature,
    timestamp: timestamp,
    rawBody: rawBody,
  );

  /// Verifies a webhook from the exact body bytes received. Prefer this when
  /// your framework exposes the raw bytes. Errors are the same as for
  /// [verifyWebhook].
  WebhookPayload verifyWebhookBytes({
    required String signature,
    required String timestamp,
    required List<int> body,
  }) => _verifier.verifyBytes(
    signature: signature,
    timestamp: timestamp,
    body: body,
  );

  WebhookVerifier get _verifier {
    final verifier = _webhookVerifier;
    if (verifier == null) {
      throw StateError(
        'Webhook secret not configured. '
        'Set webhookSecret in YallaPayConfig to verify webhooks.',
      );
    }
    return verifier;
  }

  /// Closes the underlying HTTP client.
  void dispose() {
    _dio.close();
  }

  /// Formats [date] as `YYYY-MM-DD`, the format of `transactionDate`.
  static String formatTransactionDate(DateTime date) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${date.year.toString().padLeft(4, '0')}-'
        '${two(date.month)}-${two(date.day)}';
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
