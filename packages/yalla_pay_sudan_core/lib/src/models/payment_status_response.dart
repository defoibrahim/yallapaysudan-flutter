import 'package:equatable/equatable.dart';

import '../internal/json.dart';
import 'enums.dart';

/// The gateway's answer to a payment status check.
class PaymentStatusResponse extends Equatable {
  /// Your reference ID for the payment.
  final String clientReferenceId;

  /// The gateway's transaction ID.
  final String paymentReferenceId;

  /// The payment status. [PaymentStatus.unknown] if the gateway sent a
  /// status this package does not know; see [rawStatus].
  final PaymentStatus status;

  /// The status exactly as the gateway sent it.
  final String rawStatus;

  /// Transaction amount in SDG, or `0` if not sent.
  final num amount;

  /// Date the payment was processed (YYYY-MM-DD), or empty if not sent.
  final String paymentDate;

  /// Time the payment was processed (HH:MM:SS), or empty if not sent.
  final String paymentTime;

  /// The full decoded response body.
  final Map<String, dynamic> raw;

  /// Creates a [PaymentStatusResponse].
  const PaymentStatusResponse({
    required this.clientReferenceId,
    required this.paymentReferenceId,
    required this.status,
    required this.rawStatus,
    required this.amount,
    required this.paymentDate,
    required this.paymentTime,
    required this.raw,
  });

  /// Whether the payment went through.
  bool get isSuccessful => status == PaymentStatus.successful;

  /// Reads a status response. `status` is required.
  ///
  /// Throws `InvalidResponseException` if `status` is missing or a field has
  /// an unusable type.
  factory PaymentStatusResponse.fromJson(Map<String, dynamic> json) {
    final rawStatus = requireString(json, 'status');
    return PaymentStatusResponse(
      clientReferenceId: readString(json, 'clientReferenceId') ?? '',
      paymentReferenceId: readString(json, 'paymentReferenceId') ?? '',
      status: PaymentStatus.fromString(rawStatus),
      rawStatus: rawStatus,
      amount: readNum(json, 'amount') ?? 0,
      paymentDate: readString(json, 'paymentDate') ?? '',
      paymentTime: readString(json, 'paymentTime') ?? '',
      raw: json,
    );
  }

  @override
  List<Object?> get props => [
    clientReferenceId,
    paymentReferenceId,
    status,
    rawStatus,
    amount,
    paymentDate,
    paymentTime,
  ];
}
