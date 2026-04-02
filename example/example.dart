import 'package:flutter/material.dart';
import 'package:yalla_pay_sudan/yalla_pay_sudan.dart';

final client = YallaPayClient(
  YallaPayConfig(
    apiKey: 'your-auth-token',
    baseUrl: ApiConstants.sandboxBaseUrl,
  ),
);

void main() => runApp(const MaterialApp(home: PaymentScreen()));

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  Future<void> _pay() async {
    final response = await client.createPayment(
      PaymentRequest(
        amount: 5000,
        clientReferenceId: 'order-${DateTime.now().millisecondsSinceEpoch}',
        description: 'Example product',
        paymentSuccessfulRedirectUrl: 'https://myapp.com/success',
        paymentFailedRedirectUrl: 'https://myapp.com/failed',
      ),
    );

    if (!mounted) return;

    final result = await YallaPayCheckoutWebView.show(
      context,
      response: response,
    );

    if (result?.isSuccessful ?? false) {
      // Payment completed
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: _pay,
          child: const Text('Pay 5,000 SDG'),
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
