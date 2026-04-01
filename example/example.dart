import 'package:flutter/material.dart';
import 'package:yalla_pay_sudan/yalla_pay_sudan.dart';

/// Initialize the client with your API key from the YallaPaySudan dashboard.
final client = YallaPayClient(
  YallaPayConfig(
    apiKey: 'your-authorization-token',
    webhookSecret: 'your-webhook-secret', // optional
  ),
);

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: PaymentScreen());
  }
}

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool _loading = false;
  String? _message;

  /// Creates a one-time payment and opens the checkout WebView.
  Future<void> _pay() async {
    setState(() {
      _loading = true;
      _message = null;
    });

    try {
      final response = await client.createPayment(
        const PaymentRequest(
          amount: 5000,
          clientReferenceId: 'order-001',
          description: 'Example product',
          paymentSuccessfulRedirectUrl: 'https://myapp.com/success',
          paymentFailedRedirectUrl: 'https://myapp.com/failed',
        ),
      );

      if (!mounted) return;

      // Open in-app checkout
      final result = await YallaPayCheckoutWebView.show(
        context,
        paymentUrl: response.paymentUrl,
        successUrlPattern: 'https://myapp.com/success',
        failedUrlPattern: 'https://myapp.com/failed',
      );

      setState(() {
        _message = switch (result?.status) {
          CheckoutStatus.success => 'Payment successful!',
          CheckoutStatus.failed => 'Payment failed.',
          CheckoutStatus.cancelled => 'Payment cancelled.',
          null => 'Checkout dismissed.',
        };
      });
    } on PaymentException catch (e) {
      setState(() => _message = 'API error: ${e.message}');
    } on NetworkException catch (e) {
      setState(() => _message = 'Network error: ${e.message}');
    } finally {
      setState(() => _loading = false);
    }
  }

  /// Creates a monthly subscription.
  Future<void> _subscribe() async {
    setState(() {
      _loading = true;
      _message = null;
    });

    try {
      final response = await client.createSubscription(
        const SubscriptionRequest(
          amount: 3000,
          clientReferenceId: 'sub-001',
          description: 'Monthly plan',
          subscriptionConfiguration: SubscriptionConfiguration(
            interval: SubscriptionInterval.month,
            intervalCycle: 1,
            totalCycles: 12,
          ),
        ),
      );

      if (!mounted) return;

      final result = await YallaPayCheckoutWebView.show(
        context,
        paymentUrl: response.paymentUrl,
        successUrlPattern: 'https://myapp.com/success',
        failedUrlPattern: 'https://myapp.com/failed',
      );

      setState(() {
        _message = switch (result?.status) {
          CheckoutStatus.success => 'Subscription started!',
          CheckoutStatus.failed => 'Subscription failed.',
          CheckoutStatus.cancelled => 'Subscription cancelled.',
          null => 'Checkout dismissed.',
        };
      });
    } on YallaPayException catch (e) {
      setState(() => _message = 'Error: ${e.message}');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('YallaPay Example')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: _loading ? null : _pay,
                child: const Text('Pay 5,000 SDG'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loading ? null : _subscribe,
                child: const Text('Subscribe 3,000 SDG/month'),
              ),
              const SizedBox(height: 24),
              if (_loading) const CircularProgressIndicator(),
              if (_message != null)
                Text(_message!, style: const TextStyle(fontSize: 16)),
            ],
          ),
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
