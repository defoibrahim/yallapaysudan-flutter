import 'package:flutter/material.dart';
import 'package:yalla_pay_sudan/yalla_pay_sudan.dart';

void main() => runApp(const MaterialApp(home: PaymentExample()));

class PaymentExample extends StatefulWidget {
  const PaymentExample({super.key});

  @override
  State<PaymentExample> createState() => _PaymentExampleState();
}

class _PaymentExampleState extends State<PaymentExample> {
  // 1. Create the client (use .sandbox() for testing, .live() for production)
  final client = YallaPayClient(
    YallaPayConfig.sandbox(apiKey: 'your-test-auth-token'),
  );

  String _status = '';

  // 2. Create a payment and open the checkout WebView
  Future<void> _createPayment() async {
    try {
      final response = await client.createPayment(
        PaymentRequest(
          amount: 5000, // SDG, minimum 1,000
          clientReferenceId: 'order-${DateTime.now().millisecondsSinceEpoch}',
          description: 'Example product',
          paymentSuccessfulRedirectUrl: 'https://myapp.com/success',
          paymentFailedRedirectUrl: 'https://myapp.com/failed',
        ),
      );

      if (!mounted) return;

      // 3. Open in-app checkout — redirect URLs are auto-detected from response
      final result = await YallaPayCheckoutWebView.show(
        context,
        response: response,
      );

      // 4. Handle the result
      setState(() {
        _status = switch (result?.status) {
          PaymentStatus.successful => 'Payment successful!',
          PaymentStatus.failed => 'Payment failed.',
          PaymentStatus.cancelled => 'Payment cancelled.',
          _ => 'Checkout dismissed.',
        };
      });
    } on PaymentException catch (e) {
      setState(() => _status = 'API error: ${e.message}');
    } on NetworkException catch (e) {
      setState(() => _status = 'Network error: ${e.message}');
    }
  }

  // 5. Create a subscription
  Future<void> _createSubscription() async {
    try {
      final response = await client.createSubscription(
        SubscriptionRequest(
          amount: 3000,
          clientReferenceId: 'sub-${DateTime.now().millisecondsSinceEpoch}',
          description: 'Monthly plan',
          subscriptionConfiguration: const SubscriptionConfiguration(
            interval: SubscriptionInterval.month,
            intervalCycle: 1,
            totalCycles: 12, // omit for indefinite
          ),
        ),
      );

      if (!mounted) return;

      await YallaPayCheckoutWebView.show(context, response: response);
    } on YallaPayException catch (e) {
      setState(() => _status = 'Error: ${e.message}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('YallaPay Sudan')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _createPayment,
              child: const Text('Pay 5,000 SDG'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _createSubscription,
              child: const Text('Subscribe 3,000 SDG/mo'),
            ),
            if (_status.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(_status, style: Theme.of(context).textTheme.titleMedium),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    client.dispose();
    super.dispose();
  }
}
