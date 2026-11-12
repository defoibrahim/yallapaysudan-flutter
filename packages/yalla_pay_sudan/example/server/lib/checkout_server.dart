import 'dart:convert';
import 'dart:math';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:yalla_pay_sudan_core/yalla_pay_sudan_core.dart';

/// Reference checkout backend for the example app.
///
/// It owns the [YallaPayClient] (and with it the auth token and webhook
/// secret). The app only ever receives a checkout URL and the redirect URLs,
/// and asks this server for the order status afterwards.
class CheckoutServer {
  /// Creates the server. Redirect URLs are built under [redirectBase]; the
  /// app's checkout WebView intercepts them, so they are never loaded.
  CheckoutServer({
    required this.client,
    Uri? redirectBase,
    DateTime Function()? clock,
  }) : redirectBase =
           redirectBase ?? Uri.parse('https://example.com/yallapay'),
       _clock = clock ?? DateTime.now;

  /// The gateway client. Holds the secrets.
  final YallaPayClient client;

  /// Base of the success and failure redirect URLs.
  final Uri redirectBase;

  final DateTime Function() _clock;
  final Map<String, _Order> _orders = {};
  final Random _random = Random.secure();

  /// The request handler.
  Handler get handler {
    final router = Router()
      ..post('/checkout', _checkout)
      ..get('/orders/<id>', _order)
      ..post('/webhooks/yallapay', _webhook);
    return router.call;
  }

  Future<Response> _checkout(Request request) async {
    final Object? body;
    try {
      body = jsonDecode(await request.readAsString());
    } on FormatException {
      return _json(400, {'error': 'Expected a JSON body.'});
    }
    final kind = body is Map<String, dynamic> ? body['kind'] : null;
    if (kind != 'payment' && kind != 'subscription') {
      return _json(400, {'error': 'kind must be "payment" or "subscription".'});
    }

    final orderId =
        '$kind-${_clock().millisecondsSinceEpoch}-'
        '${_random.nextInt(1 << 32).toRadixString(16)}';
    final successUrl = _redirect('success');
    final failedUrl = _redirect('failed');

    try {
      final response = kind == 'payment'
          ? await client.createPayment(
              PaymentRequest(
                amount: 5000,
                clientReferenceId: orderId,
                description: 'Example product',
                paymentSuccessfulRedirectUrl: successUrl,
                paymentFailedRedirectUrl: failedUrl,
              ),
            )
          : await client.createSubscription(
              SubscriptionRequest(
                amount: 3000,
                clientReferenceId: orderId,
                description: 'Monthly plan',
                paymentSuccessfulRedirectUrl: successUrl,
                paymentFailedRedirectUrl: failedUrl,
                subscriptionConfiguration: const SubscriptionConfiguration(
                  interval: SubscriptionInterval.month,
                  intervalCycle: 1,
                  totalCycles: 12,
                ),
              ),
            );
      _orders[orderId] = _Order(_clock());
      return _json(200, {
        'orderId': orderId,
        'paymentUrl': response.paymentUrl,
        'successUrl': successUrl,
        'failedUrl': failedUrl,
      });
    } on YallaPayException catch (e) {
      return _json(502, {'error': e.message});
    }
  }

  Future<Response> _order(Request request, String id) async {
    final order = _orders[id];
    if (order == null) return _json(404, {'error': 'Unknown order.'});

    // No webhook yet (for example on a laptop the gateway cannot reach):
    // ask the gateway directly.
    if (order.status == null) {
      try {
        final status = await client.getPaymentStatus(
          clientReferenceId: id,
          transactionDate: order.createdAt,
        );
        if (status.status != PaymentStatus.unknown) {
          order.status = status.status;
        }
      } on YallaPayException {
        // Not known to the gateway yet, or unreachable: still pending.
      }
    }
    return _json(200, {
      'orderId': id,
      'status': order.status?.name ?? 'pending',
    });
  }

  Future<Response> _webhook(Request request) async {
    // Verify the exact bytes received, before any parsing.
    final body = await request.read().expand((chunk) => chunk).toList();
    try {
      final payload = client.verifyWebhookBytes(
        signature: request.headers['yallapay-signature'] ?? '',
        timestamp: request.headers['yallapay-timestamp'] ?? '',
        body: body,
      );
      // Setting the same status again is harmless, so repeated deliveries
      // are idempotent.
      final order = _orders[payload.clientReferenceId];
      if (order != null && payload.status != PaymentStatus.unknown) {
        order.status = payload.status;
      }
      return _json(200, {'received': true});
    } on InvalidSignatureException {
      return _json(401, {'error': 'Invalid signature.'});
    } on InvalidResponseException {
      return _json(400, {'error': 'Invalid payload.'});
    } on StateError {
      return _json(503, {'error': 'Webhook secret not configured.'});
    }
  }

  String _redirect(String outcome) =>
      redirectBase.replace(path: '${redirectBase.path}/$outcome').toString();

  static Response _json(int status, Map<String, Object?> body) => Response(
    status,
    body: jsonEncode(body),
    headers: {'content-type': 'application/json'},
  );
}

class _Order {
  _Order(this.createdAt);

  final DateTime createdAt;
  PaymentStatus? status;
}
