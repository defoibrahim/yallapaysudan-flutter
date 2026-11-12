import 'package:equatable/equatable.dart';
import 'package:yalla_pay_sudan_core/yalla_pay_sudan_core.dart'
    show PaymentStatus;

/// How an in-app checkout ended, as seen by the WebView.
///
/// **A UI hint, not proof of payment.** The WebView only sees which redirect
/// URL the page navigated to, and a cancelled checkout may still have been
/// paid. Use it to decide what to show next, then ask your backend, which
/// learns the real outcome from the verified webhook or a status check.
class CheckoutResult extends Equatable {
  /// [PaymentStatus.successful] or [PaymentStatus.failed] when the checkout
  /// reached a redirect URL, [PaymentStatus.cancelled] when the customer
  /// closed it.
  final PaymentStatus status;

  /// The redirect URL the checkout navigated to, including any query
  /// parameters the gateway added. `null` when cancelled.
  final String? redirectUrl;

  /// Creates a [CheckoutResult].
  const CheckoutResult({required this.status, this.redirectUrl});

  /// Whether the checkout reached the success redirect URL.
  bool get isSuccessful => status == PaymentStatus.successful;

  /// Whether the checkout reached the failure redirect URL.
  bool get isFailed => status == PaymentStatus.failed;

  /// Whether the customer closed the checkout.
  bool get isCancelled => status == PaymentStatus.cancelled;

  @override
  List<Object?> get props => [status, redirectUrl];
}
