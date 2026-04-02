import 'package:equatable/equatable.dart';

import 'enums.dart';

/// Result returned by [YallaPayCheckoutWebView] when checkout completes.
class CheckoutResult extends Equatable {
  /// The payment outcome. `null` if the user dismissed without completing.
  final PaymentStatus status;

  /// The final URL that triggered the result, if available.
  final String? redirectUrl;

  const CheckoutResult({
    required this.status,
    this.redirectUrl,
  });

  bool get isSuccessful => status == PaymentStatus.successful;

  bool get isFailed => status == PaymentStatus.failed;

  bool get isCancelled => status == PaymentStatus.cancelled;

  @override
  List<Object?> get props => [status, redirectUrl];
}
