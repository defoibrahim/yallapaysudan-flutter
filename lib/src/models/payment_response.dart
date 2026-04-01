import 'package:equatable/equatable.dart';

/// Response from the YallaPaySudan API after creating a payment or subscription.
class PaymentResponse extends Equatable {
  /// Response code from the API. "0" indicates success.
  final String responseCode;

  /// Human-readable response message.
  final String responseMessage;

  /// Server date when the response was generated (YYYY-MM-DD).
  final String currentDate;

  /// Server time when the response was generated (HH:MM:SS).
  final String currentTime;

  /// URL to redirect the customer to for payment checkout.
  final String paymentUrl;

  /// The full raw API response.
  final Map<String, dynamic> raw;

  /// The success redirect URL from the original request.
  final String? successRedirectUrl;

  /// The failure redirect URL from the original request.
  final String? failedRedirectUrl;

  const PaymentResponse({
    required this.responseCode,
    required this.responseMessage,
    required this.currentDate,
    required this.currentTime,
    required this.paymentUrl,
    required this.raw,
    this.successRedirectUrl,
    this.failedRedirectUrl,
  });

  /// Whether the API request was successful.
  bool get isSuccess => responseCode == '0';

  /// Creates a [PaymentResponse] from the API JSON response.
  factory PaymentResponse.fromJson(Map<String, dynamic> json) {
    return PaymentResponse(
      responseCode: json['responseCode'] as String? ?? '',
      responseMessage: json['responseMessage'] as String? ?? '',
      currentDate: json['currentDate'] as String? ?? '',
      currentTime: json['currentTime'] as String? ?? '',
      paymentUrl: json['paymentUrl'] as String? ?? '',
      raw: json,
    );
  }

  /// Returns a copy with the redirect URLs attached.
  PaymentResponse copyWith({
    String? successRedirectUrl,
    String? failedRedirectUrl,
  }) {
    return PaymentResponse(
      responseCode: responseCode,
      responseMessage: responseMessage,
      currentDate: currentDate,
      currentTime: currentTime,
      paymentUrl: paymentUrl,
      raw: raw,
      successRedirectUrl: successRedirectUrl ?? this.successRedirectUrl,
      failedRedirectUrl: failedRedirectUrl ?? this.failedRedirectUrl,
    );
  }

  @override
  List<Object?> get props => [
        responseCode,
        responseMessage,
        currentDate,
        currentTime,
        paymentUrl,
      ];
}
