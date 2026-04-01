import 'package:equatable/equatable.dart';

/// The outcome of an in-app checkout flow.
enum CheckoutStatus {
  /// Payment completed successfully.
  success,

  /// Payment failed.
  failed,

  /// User cancelled the checkout (e.g., closed the WebView).
  cancelled,
}

/// Result returned by [YallaPayCheckoutWebView] when checkout completes.
class CheckoutResult extends Equatable {
  /// The checkout outcome.
  final CheckoutStatus status;

  /// The final URL that triggered the result, if available.
  final String? redirectUrl;

  const CheckoutResult({
    required this.status,
    this.redirectUrl,
  });

  /// Whether the payment was successful.
  bool get isSuccess => status == CheckoutStatus.success;

  /// Whether the payment failed.
  bool get isFailed => status == CheckoutStatus.failed;

  /// Whether the user cancelled.
  bool get isCancelled => status == CheckoutStatus.cancelled;

  @override
  List<Object?> get props => [status, redirectUrl];
}
