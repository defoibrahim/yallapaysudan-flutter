import 'package:equatable/equatable.dart';

import '../api/api_constants.dart';

/// Configuration for [YallaPayClient].
///
/// **Server-side only.** [apiKey] and [webhookSecret] are secrets. Read them
/// from your server's environment or secret store; never compile them into a
/// mobile or web app, where anyone can extract them.
class YallaPayConfig extends Equatable {
  /// The merchant auth token from the YallaPaySudan dashboard
  /// (`test_sk_...` for the sandbox, `sk_...` for production).
  final String apiKey;

  /// Base URL of the gateway API. See [ApiConstants].
  final String baseUrl;

  /// The webhook secret from the dashboard. Needed only for
  /// [YallaPayClient.verifyWebhook].
  final String? webhookSecret;

  /// How far a webhook timestamp may be from the current time, in either
  /// direction, before the webhook is rejected. Defaults to 5 minutes.
  final Duration webhookTimestampTolerance;

  /// Timeout for opening the connection. Defaults to 30 seconds.
  final Duration connectTimeout;

  /// Timeout for receiving the response. Defaults to 30 seconds.
  final Duration receiveTimeout;

  /// How many times [YallaPayClient.getPaymentStatus] retries after a
  /// network error. Status checks are read-only, so retrying is safe.
  /// Payment creation is never retried automatically. Defaults to 2.
  final int statusRetries;

  /// Delay before the first status retry; doubles on each further retry.
  /// Defaults to 500 milliseconds.
  final Duration retryDelay;

  /// Whether to log requests and responses with `dart:developer`. Defaults to
  /// `false`; enable only while developing.
  ///
  /// Headers are never logged, so the auth token is not either. Request
  /// bodies and error response bodies are logged; they contain amounts,
  /// references and redirect URLs.
  final bool enableLogging;

  /// Creates a configuration. Prefer [YallaPayConfig.sandbox] or
  /// [YallaPayConfig.live].
  const YallaPayConfig({
    required this.apiKey,
    this.baseUrl = ApiConstants.defaultBaseUrl,
    this.webhookSecret,
    this.webhookTimestampTolerance = const Duration(minutes: 5),
    this.connectTimeout = const Duration(seconds: 30),
    this.receiveTimeout = const Duration(seconds: 30),
    this.statusRetries = 2,
    this.retryDelay = const Duration(milliseconds: 500),
    this.enableLogging = false,
  });

  /// Configuration for the **sandbox** (test) environment.
  const YallaPayConfig.sandbox({
    required String apiKey,
    String? webhookSecret,
    Duration webhookTimestampTolerance = const Duration(minutes: 5),
    Duration connectTimeout = const Duration(seconds: 30),
    Duration receiveTimeout = const Duration(seconds: 30),
    int statusRetries = 2,
    Duration retryDelay = const Duration(milliseconds: 500),
    bool enableLogging = false,
  }) : this(
         apiKey: apiKey,
         baseUrl: ApiConstants.sandboxBaseUrl,
         webhookSecret: webhookSecret,
         webhookTimestampTolerance: webhookTimestampTolerance,
         connectTimeout: connectTimeout,
         receiveTimeout: receiveTimeout,
         statusRetries: statusRetries,
         retryDelay: retryDelay,
         enableLogging: enableLogging,
       );

  /// Configuration for the **production** (live) environment.
  const YallaPayConfig.live({
    required String apiKey,
    String? webhookSecret,
    Duration webhookTimestampTolerance = const Duration(minutes: 5),
    Duration connectTimeout = const Duration(seconds: 30),
    Duration receiveTimeout = const Duration(seconds: 30),
    int statusRetries = 2,
    Duration retryDelay = const Duration(milliseconds: 500),
    bool enableLogging = false,
  }) : this(
         apiKey: apiKey,
         webhookSecret: webhookSecret,
         webhookTimestampTolerance: webhookTimestampTolerance,
         connectTimeout: connectTimeout,
         receiveTimeout: receiveTimeout,
         statusRetries: statusRetries,
         retryDelay: retryDelay,
         enableLogging: enableLogging,
       );

  @override
  List<Object?> get props => [
    apiKey,
    baseUrl,
    webhookSecret,
    webhookTimestampTolerance,
    connectTimeout,
    receiveTimeout,
    statusRetries,
    retryDelay,
    enableLogging,
  ];

  /// Redacts the secrets, so logging a config never leaks them.
  @override
  String toString() =>
      'YallaPayConfig(baseUrl: $baseUrl, apiKey: <redacted>, '
      'webhookSecret: ${webhookSecret == null ? 'null' : '<redacted>'})';
}
