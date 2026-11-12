// Every ```dart sample in README.md must appear here verbatim (checked in CI by
// tool/ci/check_readme_snippets.py), so the samples are analyzed and compile.
// ignore_for_file: unused_local_variable

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yalla_pay_sudan/yalla_pay_sudan.dart';

void main() {
  test('README samples compile', () {
    expect(openCheckout, isA<Function>());
  });
}

/// What the app's backend returned for a new checkout.
class CheckoutSession {
  const CheckoutSession(this.paymentUrl, this.successUrl, this.failedUrl);

  final String paymentUrl;
  final String successUrl;
  final String failedUrl;
}

Future<void> openCheckout(BuildContext context, CheckoutSession session) async {
  final result = await YallaPayCheckoutWebView.show(
    context,
    paymentUrl: session.paymentUrl,
    successUrl: session.successUrl,
    failedUrl: session.failedUrl,
  );

  if (result.isSuccessful) {
    // Say "confirming your payment", then ask your backend for the order.
  } else if (result.isFailed) {
    // Offer to try again.
  } else {
    // Closed by the customer. It may still have been paid: ask your backend.
  }
}

Future<void> extraHosts(BuildContext context, CheckoutSession session) async {
  final result = await YallaPayCheckoutWebView.show(
    context,
    paymentUrl: session.paymentUrl,
    successUrl: session.successUrl,
    failedUrl: session.failedUrl,
    allowedHosts: [
      ...YallaPayCheckoutWebView.defaultAllowedHosts,
      'secure.your-bank.example',
    ],
    onNavigationBlocked: (uri) => debugPrint('Blocked navigation to $uri'),
  );
}

class EmbeddedCheckout extends StatelessWidget {
  const EmbeddedCheckout({super.key, required this.session});

  final CheckoutSession session;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: YallaPayCheckoutWebView(
        paymentUrl: session.paymentUrl,
        successUrl: session.successUrl,
        failedUrl: session.failedUrl,
        onCheckoutResult: (result) => Navigator.of(context).pop(result),
        loadingWidget: const Center(child: Text('Loading checkout...')),
        errorBuilder: (context, message, retry) => Center(
          child: TextButton(onPressed: retry, child: Text('Retry ($message)')),
        ),
      ),
    );
  }
}
