// The smallest complete use of yalla_pay_sudan. The full example app is in
// lib/, and the backend it talks to is in server/.
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:material_ui/material_ui.dart';
import 'package:yalla_pay_sudan/yalla_pay_sudan.dart';

/// Your backend. It creates the payment with yalla_pay_sudan_core, so the
/// YallaPaySudan auth token never ships inside the app.
final backend = Uri.parse('https://api.your-shop.example');

void main() => runApp(const MaterialApp(home: CheckoutExample()));

class CheckoutExample extends StatefulWidget {
  const CheckoutExample({super.key});

  @override
  State<CheckoutExample> createState() => _CheckoutExampleState();
}

class _CheckoutExampleState extends State<CheckoutExample> {
  String _status = '';

  Future<void> _pay() async {
    // 1. Ask your backend to start a checkout. It answers with the checkout
    //    URL and the redirect URLs it created the payment with.
    final response = await http.post(backend.resolve('/checkout'));
    final session = jsonDecode(response.body) as Map<String, dynamic>;
    if (!mounted) return;

    // 2. Open the checkout in the app.
    final result = await YallaPayCheckoutWebView.show(
      context,
      paymentUrl: session['paymentUrl'] as String,
      successUrl: session['successUrl'] as String,
      failedUrl: session['failedUrl'] as String,
    );

    // 3. The result is a hint for the UI. Your backend confirms the payment
    //    from the verified webhook before you fulfil the order.
    if (!mounted) return;
    setState(() {
      _status = switch (result.status) {
        PaymentStatus.successful => 'Thanks! Confirming your payment...',
        PaymentStatus.failed => 'The payment failed. Please try again.',
        PaymentStatus.cancelled => 'Checkout closed.',
        PaymentStatus.revoked ||
        PaymentStatus.expired ||
        PaymentStatus.unknown => 'Checking the payment status...',
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('YallaPay Sudan')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FilledButton(onPressed: _pay, child: const Text('Pay 5,000 SDG')),
            const SizedBox(height: 24),
            Text(_status),
          ],
        ),
      ),
    );
  }
}
