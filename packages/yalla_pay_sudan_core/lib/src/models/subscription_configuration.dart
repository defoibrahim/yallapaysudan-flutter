import 'package:equatable/equatable.dart';

import 'enums.dart';

/// Configuration for recurring subscription billing.
class SubscriptionConfiguration extends Equatable {
  /// The billing interval (DAY, MONTH, or YEAR).
  final SubscriptionInterval interval;

  /// Number of intervals between each charge.
  final int intervalCycle;

  /// Total number of billing cycles. Omit (null) for indefinite.
  final int? totalCycles;

  /// Creates a [SubscriptionConfiguration]. For example, every month for a
  /// year: `interval: SubscriptionInterval.month, intervalCycle: 1,
  /// totalCycles: 12`.
  const SubscriptionConfiguration({
    required this.interval,
    required this.intervalCycle,
    this.totalCycles,
  });

  /// Validates the configuration fields.
  ///
  /// Throws [ArgumentError] if validation fails.
  void validate() {
    if (intervalCycle < 1) {
      throw ArgumentError.value(
        intervalCycle,
        'intervalCycle',
        'Must be at least 1',
      );
    }
    if (totalCycles != null && totalCycles! < 1) {
      throw ArgumentError.value(
        totalCycles,
        'totalCycles',
        'Must be at least 1 when set',
      );
    }
  }

  /// The JSON object sent to the gateway.
  Map<String, dynamic> toJson() {
    return {
      'interval': interval.toApiValue(),
      'intervalCycle': '$intervalCycle',
      if (totalCycles != null) 'totalCycles': '$totalCycles',
    };
  }

  @override
  List<Object?> get props => [interval, intervalCycle, totalCycles];
}
