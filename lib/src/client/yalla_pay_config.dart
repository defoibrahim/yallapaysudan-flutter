import 'package:equatable/equatable.dart';

import '../api/api_constants.dart';

/// Configuration for the YallaPaySudan client.
class YallaPayConfig extends Equatable {
  /// The API authorization token from the merchant dashboard.
  final String apiKey;

  /// Base URL for the YallaPaySudan API.
  final String baseUrl;

  /// Webhook secret key for signature verification.
  /// Required only if using [YallaPayClient.verifyWebhook].
  final String? webhookSecret;

  /// Maximum allowed age for webhook timestamps.
  final Duration webhookTimestampTolerance;

  /// Connection timeout for HTTP requests.
  final Duration connectTimeout;

  /// Response receive timeout for HTTP requests.
  final Duration receiveTimeout;

  /// Whether to enable debug logging of requests and responses.
  final bool enableLogging;

  const YallaPayConfig({
    required this.apiKey,
    this.baseUrl = ApiConstants.defaultBaseUrl,
    this.webhookSecret,
    this.webhookTimestampTolerance = const Duration(minutes: 5),
    this.connectTimeout = const Duration(seconds: 30),
    this.receiveTimeout = const Duration(seconds: 30),
    this.enableLogging = false,
  });

  /// Creates a config for the **sandbox** (test) environment.
  const YallaPayConfig.sandbox({
    required String apiKey,
    String? webhookSecret,
    Duration webhookTimestampTolerance = const Duration(minutes: 5),
    Duration connectTimeout = const Duration(seconds: 30),
    Duration receiveTimeout = const Duration(seconds: 30),
    bool enableLogging = false,
  }) : this(
         apiKey: apiKey,
         baseUrl: ApiConstants.sandboxBaseUrl,
         webhookSecret: webhookSecret,
         webhookTimestampTolerance: webhookTimestampTolerance,
         connectTimeout: connectTimeout,
         receiveTimeout: receiveTimeout,
         enableLogging: enableLogging,
       );

  /// Creates a config for the **production** (live) environment.
  const YallaPayConfig.live({
    required String apiKey,
    String? webhookSecret,
    Duration webhookTimestampTolerance = const Duration(minutes: 5),
    Duration connectTimeout = const Duration(seconds: 30),
    Duration receiveTimeout = const Duration(seconds: 30),
    bool enableLogging = false,
  }) : this(
         apiKey: apiKey,
         webhookSecret: webhookSecret,
         webhookTimestampTolerance: webhookTimestampTolerance,
         connectTimeout: connectTimeout,
         receiveTimeout: receiveTimeout,
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
    enableLogging,
  ];
}
