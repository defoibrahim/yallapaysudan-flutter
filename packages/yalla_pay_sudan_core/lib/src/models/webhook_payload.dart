import 'package:equatable/equatable.dart';

import '../internal/json.dart';
import 'enums.dart';

/// A verified webhook notification from YallaPaySudan.
///
/// Webhooks can be delivered more than once. Make your handler idempotent,
/// for example by ignoring a [paymentReferenceId] and [status] pair you have
/// already processed.
class WebhookPayload extends Equatable {
  /// Your reference ID for the payment.
  final String clientReferenceId;

  /// The gateway's transaction ID.
  final String paymentReferenceId;

  /// The payment status. [PaymentStatus.unknown] if the gateway sent a
  /// status this package does not know; see [rawStatus].
  final PaymentStatus status;

  /// The status exactly as the gateway sent it.
  final String rawStatus;

  /// Event time in Unix milliseconds, from the body.
  final int timestamp;

  /// The full decoded body.
  final Map<String, dynamic> raw;

  /// Creates a [WebhookPayload].
  const WebhookPayload({
    required this.clientReferenceId,
    required this.paymentReferenceId,
    required this.status,
    required this.rawStatus,
    required this.timestamp,
    required this.raw,
  });

  /// Whether the payment went through.
  bool get isSuccessful => status == PaymentStatus.successful;

  /// Whether the payment failed.
  bool get isFailed => status == PaymentStatus.failed;

  /// Whether the payment was cancelled.
  bool get isCancelled => status == PaymentStatus.cancelled;

  /// Reads a webhook body. All fields are required.
  ///
  /// Throws `InvalidResponseException` if a field is missing or has an
  /// unusable type.
  factory WebhookPayload.fromJson(Map<String, dynamic> json) {
    final rawStatus = requireString(json, 'status');
    return WebhookPayload(
      clientReferenceId: requireString(json, 'clientReferenceId'),
      paymentReferenceId: requireString(json, 'paymentReferenceId'),
      status: PaymentStatus.fromString(rawStatus),
      rawStatus: rawStatus,
      timestamp: requireInt(json, 'timestamp'),
      raw: json,
    );
  }

  @override
  List<Object?> get props => [
    clientReferenceId,
    paymentReferenceId,
    status,
    rawStatus,
    timestamp,
  ];
}
