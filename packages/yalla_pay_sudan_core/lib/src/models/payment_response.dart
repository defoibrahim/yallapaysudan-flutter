import 'package:equatable/equatable.dart';

import '../internal/json.dart';

/// The gateway's answer to a payment or subscription link request.
class PaymentResponse extends Equatable {
  /// Response code from the gateway. `"0"` means success.
  final String responseCode;

  /// Human-readable message from the gateway.
  final String responseMessage;

  /// Server date of the response (YYYY-MM-DD), or empty if not sent.
  final String currentDate;

  /// Server time of the response (HH:MM:SS), or empty if not sent.
  final String currentTime;

  /// The hosted checkout URL to open for the customer. Empty when the
  /// request failed.
  final String paymentUrl;

  /// The full decoded response body.
  final Map<String, dynamic> raw;

  /// The success redirect URL from the request, attached by
  /// `YallaPayClient` so the checkout can watch for it.
  final String? successRedirectUrl;

  /// The failure redirect URL from the request, attached by
  /// `YallaPayClient`.
  final String? failedRedirectUrl;

  /// Creates a [PaymentResponse].
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

  /// Whether the gateway accepted the request (`responseCode == "0"`).
  bool get isSuccess => responseCode == '0';

  /// Reads a gateway response. Missing fields become empty strings; numeric
  /// codes are converted to strings.
  ///
  /// Throws `InvalidResponseException` if a field has an unusable type.
  factory PaymentResponse.fromJson(Map<String, dynamic> json) {
    return PaymentResponse(
      responseCode: readString(json, 'responseCode') ?? '',
      responseMessage: readString(json, 'responseMessage') ?? '',
      currentDate: readString(json, 'currentDate') ?? '',
      currentTime: readString(json, 'currentTime') ?? '',
      paymentUrl: readString(json, 'paymentUrl') ?? '',
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
    successRedirectUrl,
    failedRedirectUrl,
  ];
}
