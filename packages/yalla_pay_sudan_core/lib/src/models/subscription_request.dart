import 'package:equatable/equatable.dart';

import 'subscription_configuration.dart';

/// Request model for creating a subscription payment link.
class SubscriptionRequest extends Equatable {
  /// Payment amount per cycle in SDG (minimum 1,000).
  final double amount;

  /// Unique subscription identifier on the merchant's side.
  final String clientReferenceId;

  /// Customer-facing payment description.
  final String? description;

  /// URL to redirect to after successful payment.
  final String? paymentSuccessfulRedirectUrl;

  /// URL to redirect to after failed payment.
  final String? paymentFailedRedirectUrl;

  /// Whether the customer pays the gateway commission.
  final bool commissionPaidByCustomer;

  /// Recurring billing configuration.
  final SubscriptionConfiguration subscriptionConfiguration;

  const SubscriptionRequest({
    required this.amount,
    required this.clientReferenceId,
    required this.subscriptionConfiguration,
    this.description,
    this.paymentSuccessfulRedirectUrl,
    this.paymentFailedRedirectUrl,
    this.commissionPaidByCustomer = false,
  });

  /// Validates the request fields.
  ///
  /// Throws [ArgumentError] if validation fails.
  void validate() {
    if (amount < 1000) {
      throw ArgumentError('Amount must be at least 1,000 SDG, got: $amount');
    }
    if (clientReferenceId.isEmpty) {
      throw ArgumentError('clientReferenceId must not be empty');
    }
    subscriptionConfiguration.validate();
  }

  /// Converts to JSON map for API submission.
  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
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
