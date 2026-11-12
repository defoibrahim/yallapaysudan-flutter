import 'package:equatable/equatable.dart';

import '../internal/validation.dart';

/// Request for a one-time payment link.
class PaymentRequest extends Equatable {
  /// The smallest amount, in SDG, the gateway accepts.
  static const num minimumAmount = 1000;

  /// Amount to charge, in SDG: a finite number of at least [minimumAmount].
  final num amount;

  /// Your unique ID for this payment, for example your order ID.
  ///
  /// The gateway accepts each reference once, which makes it the idempotency
  /// key for payment creation. Reuse it to look the payment up with
  /// `YallaPayClient.getPaymentStatus`.
  final String clientReferenceId;

  /// Description shown to the customer on the checkout page.
  final String? description;

  /// Absolute http(s) URL the checkout redirects to after a successful
  /// payment. The in-app checkout watches for this URL.
  final String? paymentSuccessfulRedirectUrl;

  /// Absolute http(s) URL the checkout redirects to after a failed payment.
  final String? paymentFailedRedirectUrl;

  /// Whether the customer pays the gateway commission. Defaults to `false`
  /// (the merchant pays).
  final bool commissionPaidByCustomer;

  /// Creates a [PaymentRequest]. Call [validate] (or let `YallaPayClient` do
  /// it) before sending.
  const PaymentRequest({
    required this.amount,
    required this.clientReferenceId,
    this.description,
    this.paymentSuccessfulRedirectUrl,
    this.paymentFailedRedirectUrl,
    this.commissionPaidByCustomer = false,
  });

  /// Checks the fields before anything is sent.
  ///
  /// Throws [ArgumentError] if [amount] is not finite or below
  /// [minimumAmount], [clientReferenceId] is blank, or a redirect URL is not
  /// an absolute http(s) URL.
  void validate() {
    validateAmount(amount, minimumAmount);
    validateReference(clientReferenceId);
    validateRedirectUrl(
      paymentSuccessfulRedirectUrl,
      'paymentSuccessfulRedirectUrl',
    );
    validateRedirectUrl(paymentFailedRedirectUrl, 'paymentFailedRedirectUrl');
  }

  /// The JSON body sent to the gateway.
  Map<String, dynamic> toJson() {
    return {
      'amount': amountToJson(amount),
      'clientReferenceId': clientReferenceId,
      if (description != null) 'description': description,
      if (paymentSuccessfulRedirectUrl != null)
        'paymentSuccessfulRedirectUrl': paymentSuccessfulRedirectUrl,
      if (paymentFailedRedirectUrl != null)
        'paymentFailedRedirectUrl': paymentFailedRedirectUrl,
      'commissionPaidByCustomer': commissionPaidByCustomer,
    };
  }

  @override
  List<Object?> get props => [
    amount,
    clientReferenceId,
    description,
    paymentSuccessfulRedirectUrl,
    paymentFailedRedirectUrl,
    commissionPaidByCustomer,
  ];
}
