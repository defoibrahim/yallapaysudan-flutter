import 'package:equatable/equatable.dart';

import 'enums.dart';

/// Response from the payment status check endpoint.
class PaymentStatusResponse extends Equatable {
  /// The merchant's unique transaction ID.
  final String clientReferenceId;

  /// YallaPaySudan's internal transaction ID.
  final String paymentReferenceId;

  /// Current payment status.
  final PaymentStatus status;

  /// Transaction amount in SDG.
  final double amount;

  /// Date the payment was processed (YYYY-MM-DD).
  final String paymentDate;

  /// Time the payment was processed (HH:MM:SS).
  final String paymentTime;

  /// The full raw API response.
  final Map<String, dynamic> raw;

  const PaymentStatusResponse({
    required this.clientReferenceId,
    required this.paymentReferenceId,
    required this.status,
    required this.amount,
    required this.paymentDate,
    required this.paymentTime,
    required this.raw,
  });

  /// Whether the payment was successful.
  bool get isSuccessful => status == PaymentStatus.successful;

  /// Creates a [PaymentStatusResponse] from the API JSON response.
  factory PaymentStatusResponse.fromJson(Map<String, dynamic> json) {
    return PaymentStatusResponse(
      clientReferenceId: json['clientReferenceId'] as String? ?? '',
      paymentReferenceId: json['paymentReferenceId'] as String? ?? '',
      status: PaymentStatus.fromString(json['status'] as String? ?? ''),
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      paymentDate: json['paymentDate'] as String? ?? '',
      paymentTime: json['paymentTime'] as String? ?? '',
      raw: json,
    );
  }

  @override
  List<Object?> get props => [
    clientReferenceId,
    paymentReferenceId,
    status,
    amount,
    paymentDate,
    paymentTime,
  ];
}
