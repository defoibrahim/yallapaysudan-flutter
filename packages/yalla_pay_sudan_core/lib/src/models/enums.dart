/// Interval for subscription billing cycles.
enum SubscriptionInterval {
  /// Bill every day (times `intervalCycle`).
  day,

  /// Bill every month (times `intervalCycle`).
  month,

  /// Bill every year (times `intervalCycle`).
  year;

  /// The value the gateway API expects: `DAY`, `MONTH` or `YEAR`.
  String toApiValue() => switch (this) {
    SubscriptionInterval.day => 'DAY',
    SubscriptionInterval.month => 'MONTH',
    SubscriptionInterval.year => 'YEAR',
  };

  /// Parses `DAY`, `MONTH` or `YEAR` (case-insensitive).
  ///
  /// Throws [ArgumentError] for any other value.
  static SubscriptionInterval fromString(String value) =>
      switch (value.toUpperCase()) {
        'DAY' => SubscriptionInterval.day,
        'MONTH' => SubscriptionInterval.month,
        'YEAR' => SubscriptionInterval.year,
        _ => throw ArgumentError.value(
          value,
          'value',
          'Invalid subscription interval',
        ),
      };
}

/// Payment status from webhooks and status checks, and the outcome of an
/// in-app checkout.
enum PaymentStatus {
  /// The payment went through.
  successful,

  /// The payment was attempted and failed.
  failed,

  /// The payment was cancelled. For an in-app checkout result this means the
  /// customer closed the checkout, which does not prove that nothing was paid.
  cancelled,

  /// The payment was reversed after it succeeded.
  revoked,

  /// The payment link expired before it was paid.
  expired,

  /// A status this version of the package does not know yet.
  ///
  /// Kept so that new gateway statuses do not break webhook handling; the
  /// original value is available as `rawStatus` on the model that carried it.
  /// Treat it as "not paid" and check again later.
  unknown;

  /// Parses a gateway status (case-insensitive). Unrecognised values map to
  /// [PaymentStatus.unknown] instead of throwing.
  static PaymentStatus fromString(String value) =>
      switch (value.trim().toUpperCase()) {
        'SUCCESSFUL' => PaymentStatus.successful,
        'FAILED' => PaymentStatus.failed,
        'CANCELLED' => PaymentStatus.cancelled,
        'REVOKED' => PaymentStatus.revoked,
        'EXPIRED' => PaymentStatus.expired,
        _ => PaymentStatus.unknown,
      };
}
