import 'dart:convert';
import 'dart:io';

import 'package:yalla_pay_sudan_core/yalla_pay_sudan_core.dart';

/// A minimal checkout backend built on `dart:io`.
///
/// * `POST /checkout` creates a sandbox payment link and returns its URL.
/// * `POST /webhooks/yallapay` verifies the webhook signature over the raw
///   body bytes.
///
/// Secrets come from the environment and never leave the server:
///
/// ```sh
/// YALLAPAY_API_KEY=test_sk_... YALLAPAY_WEBHOOK_SECRET=... \
///   dart run example/yalla_pay_sudan_core_example.dart
/// ```
Future<void> main() async {
  final client = YallaPayClient(
    YallaPayConfig.sandbox(
      apiKey: Platform.environment['YALLAPAY_API_KEY'] ?? 'missing-key',
      webhookSecret: Platform.environment['YALLAPAY_WEBHOOK_SECRET'],
    ),
  );

  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 8080);
  stdout.writeln('Listening on http://localhost:8080');

  await for (final request in server) {
    // Keep the exact bytes: the webhook signature covers them.
    final body = await request.fold<List<int>>([], (all, chunk) => all..addAll(chunk));
    try {
      if (request.method == 'POST' && request.uri.path == '/checkout') {
        final orderId = 'order-${DateTime.now().millisecondsSinceEpoch}';
        final response = await client.createPayment(
          PaymentRequest(
            amount: 5000,
            clientReferenceId: orderId,
            paymentSuccessfulRedirectUrl: 'https://example.com/payment/success',
            paymentFailedRedirectUrl: 'https://example.com/payment/failed',
          ),
        );
        _json(request.response, HttpStatus.ok, {
          'orderId': orderId,
          'paymentUrl': response.paymentUrl,
          'successUrl': response.successRedirectUrl,
          'failedUrl': response.failedRedirectUrl,
        });
      } else if (request.method == 'POST' &&
          request.uri.path == '/webhooks/yallapay') {
        final payload = client.verifyWebhookBytes(
          signature: request.headers.value('YallaPay-Signature') ?? '',
          timestamp: request.headers.value('YallaPay-TimeStamp') ?? '',
          body: body,
        );
        // Deliveries can repeat: update the order idempotently.
        stdout.writeln('${payload.clientReferenceId}: ${payload.status}');
        _json(request.response, HttpStatus.ok, {'received': true});
      } else {
        _json(request.response, HttpStatus.notFound, {'error': 'not found'});
      }
    } on InvalidSignatureException {
      _json(request.response, HttpStatus.unauthorized, {
        'error': 'bad signature',
      });
    } on YallaPayException catch (e) {
      _json(request.response, HttpStatus.badGateway, {'error': e.message});
    }
  }
}

void _json(HttpResponse response, int status, Map<String, Object?> body) {
  response
    ..statusCode = status
    ..headers.contentType = ContentType.json
    ..write(jsonEncode(body))
    ..close();
}
