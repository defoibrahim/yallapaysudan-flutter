import 'package:equatable/equatable.dart';

import '../internal/validation.dart';
import 'subscription_configuration.dart';

/// Request for a recurring subscription payment link.
class SubscriptionRequest extends Equatable {
  /// The smallest amount per cycle, in SDG, the gateway accepts.
  static const num minimumAmount = 1000;

  /// Amount to charge each cycle, in SDG: a finite number of at least
  /// [minimumAmount].
  final num amount;

  /// Your unique ID for this subscription. The gateway accepts each reference
  /// once.
  final String clientReferenceId;

  /// Description shown to the customer on the checkout page.
  final String? description;

  /// Absolute http(s) URL the checkout redirects to after a successful
  /// payment.
  final String? paymentSuccessfulRedirectUrl;

  /// Absolute http(s) URL the checkout redirects to after a failed payment.
  final String? paymentFailedRedirectUrl;

  /// Whether the customer pays the gateway commission. Defaults to `false`.
  final bool commissionPaidByCustomer;

  /// How often, and how many times, the customer is charged.
  final SubscriptionConfiguration subscriptionConfiguration;

  /// Creates a [SubscriptionRequest].
  const SubscriptionRequest({
    required this.amount,
    required this.clientReferenceId,
    required this.subscriptionConfiguration,
    this.description,
    this.paymentSuccessfulRedirectUrl,
    this.paymentFailedRedirectUrl,
    this.commissionPaidByCustomer = false,
  });

  /// Checks the fields, including [subscriptionConfiguration].
  ///
  /// Throws [ArgumentError] if any field is invalid.
  void validate() {
    validateAmount(amount, minimumAmount);
    validateReference(clientReferenceId);
    validateRedirectUrl(
      paymentSuccessfulRedirectUrl,
      'paymentSuccessfulRedirectUrl',
    );
    validateRedirectUrl(paymentFailedRedirectUrl, 'paymentFailedRedirectUrl');
    subscriptionConfiguration.validate();
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
      'subscriptionConfiguration': subscriptionConfiguration.toJson(),
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
    subscriptionConfiguration,
  ];
}
