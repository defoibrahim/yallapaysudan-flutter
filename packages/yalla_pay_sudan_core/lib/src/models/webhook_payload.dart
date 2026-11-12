import 'package:equatable/equatable.dart';

import 'enums.dart';

/// Parsed webhook payload from YallaPaySudan.
class WebhookPayload extends Equatable {
  /// The merchant's unique transaction/order ID.
  final String clientReferenceId;

  /// YallaPaySudan's internal transaction ID.
  final String paymentReferenceId;

  /// Payment status.
  final PaymentStatus status;

  /// Webhook timestamp (Unix milliseconds).
  final int timestamp;

  /// The full raw webhook payload.
  final Map<String, dynamic> raw;

  const WebhookPayload({
    required this.clientReferenceId,
    required this.paymentReferenceId,
    required this.status,
    required this.timestamp,
    required this.raw,
  });

  /// Whether the payment was successful.
  bool get isSuccessful => status == PaymentStatus.successful;

  /// Whether the payment failed.
  bool get isFailed => status == PaymentStatus.failed;

  /// Whether the payment was cancelled.
  bool get isCancelled => status == PaymentStatus.cancelled;

  /// Creates a [WebhookPayload] from the webhook JSON body.
  factory WebhookPayload.fromJson(Map<String, dynamic> json) {
    return WebhookPayload(
      clientReferenceId: json['clientReferenceId'] as String,
      paymentReferenceId: json['paymentReferenceId'] as String,
      status: PaymentStatus.fromString(json['status'] as String),
      timestamp: json['timestamp'] as int,
      raw: json,
    );
  }

  @override
  List<Object?> get props => [
    clientReferenceId,
    paymentReferenceId,
    status,
    timestamp,
  ];
}
