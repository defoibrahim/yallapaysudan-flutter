/// Interval for subscription billing cycles.
enum SubscriptionInterval {
  day,
  month,
  year;

  String toApiValue() => switch (this) {
    SubscriptionInterval.day => 'DAY',
    SubscriptionInterval.month => 'MONTH',
    SubscriptionInterval.year => 'YEAR',
  };

  static SubscriptionInterval fromString(String value) =>
      switch (value.toUpperCase()) {
        'DAY' => SubscriptionInterval.day,
        'MONTH' => SubscriptionInterval.month,
        'YEAR' => SubscriptionInterval.year,
        _ => throw ArgumentError('Invalid subscription interval: $value'),
      };
}

/// Payment status returned by webhooks and status checks.
enum PaymentStatus {
  successful,
  failed,
  cancelled,
  revoked,
  expired;

  static PaymentStatus fromString(String value) =>
      switch (value.toUpperCase()) {
        'SUCCESSFUL' => PaymentStatus.successful,
        'FAILED' => PaymentStatus.failed,
        'CANCELLED' => PaymentStatus.cancelled,
        'REVOKED' => PaymentStatus.revoked,
        'EXPIRED' => PaymentStatus.expired,
        _ => throw ArgumentError('Unknown payment status: $value'),
      };
}
