import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';
import 'package:yalla_pay_sudan_core/yalla_pay_sudan_core.dart';
import 'package:yalla_pay_sudan_example_server/checkout_server.dart';

const webhookSecret = 'whsec_example_test';

/// Answers gateway requests from [handler] instead of the network.
class FakeGateway implements HttpClientAdapter {
  FakeGateway(this.handler);

  FutureOr<Map<String, Object?>> Function(RequestOptions options) handler;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return ResponseBody.fromString(
      jsonEncode(await handler(options)),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late FakeGateway gateway;
  late Handler handler;

  setUp(() {
    gateway = FakeGateway(
      (_) => {
        'responseCode': '0',
        'responseMessage': 'Success',
        'paymentUrl': 'https://gateway.yallapaysudan.com/checkout/web/abc',
      },
    );
    final client = YallaPayClient.withDio(
      const YallaPayConfig(
        apiKey: 'test_sk_example',
        webhookSecret: webhookSecret,
        statusRetries: 0,
      ),
      Dio(BaseOptions(baseUrl: 'https://gateway.example/api/v1'))
        ..httpClientAdapter = gateway,
    );
    handler = CheckoutServer(client: client).handler;
  });

  Future<(int, Map<String, dynamic>)> call(
    String method,
    String path, {
    Object? body,
    Map<String, String> headers = const {},
  }) async {
    final response = await handler(
      Request(
        method,
        Uri.parse('http://localhost$path'),
        body: body is String ? body : jsonEncode(body),
        headers: headers,
      ),
    );
    final json =
        jsonDecode(await response.readAsString()) as Map<String, dynamic>;
    return (response.statusCode, json);
  }

  Future<String> startCheckout([String kind = 'payment']) async {
    final (status, json) = await call('POST', '/checkout', body: {'kind': kind});
    expect(status, 200);
    return json['orderId'] as String;
  }

  Map<String, String> signedHeaders(String body) {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final signature = Hmac(
      sha256,
      utf8.encode(webhookSecret),
    ).convert(utf8.encode('$timestamp.$body')).toString();
    return {'YallaPay-Signature': signature, 'YallaPay-TimeStamp': timestamp};
  }

  group('POST /checkout', () {
    test('creates a payment and returns only what the app needs', () async {
      final (status, json) = await call(
        'POST',
        '/checkout',
        body: {'kind': 'payment'},
      );

      expect(status, 200);
      expect(json.keys, {'orderId', 'paymentUrl', 'successUrl', 'failedUrl'});
      expect(json['paymentUrl'], startsWith('https://gateway.yallapaysudan'));
      expect(json['successUrl'], 'https://example.com/yallapay/success');
      expect(json['failedUrl'], 'https://example.com/yallapay/failed');

      final sent = gateway.requests.single;
      expect(sent.path, ApiConstants.generatePaymentLink);
      expect((sent.data as Map)['clientReferenceId'], json['orderId']);
      expect(jsonEncode(json), isNot(contains('test_sk_example')));
    });

    test('creates a subscription', () async {
      await startCheckout('subscription');

      expect(
        gateway.requests.single.path,
        ApiConstants.generateSubscriptionPaymentLink,
      );
    });

    test('rejects a bad request', () async {
      expect((await call('POST', '/checkout', body: 'nope')).$1, 400);
      expect((await call('POST', '/checkout', body: {'kind': 'x'})).$1, 400);
      expect(gateway.requests, isEmpty);
    });

    test('reports gateway errors as 502', () async {
      gateway.handler = (_) => {
        'responseCode': '1',
        'responseMessage': 'Invalid merchant',
      };

      final (status, json) = await call(
        'POST',
        '/checkout',
        body: {'kind': 'payment'},
      );

      expect(status, 502);
      expect(json['error'], 'Invalid merchant');
    });
  });

  group('GET /orders/<id>', () {
    test('unknown orders are 404', () async {
      expect((await call('GET', '/orders/nope')).$1, 404);
    });

    test('asks the gateway while no webhook has arrived', () async {
      final orderId = await startCheckout();
      gateway.handler = (_) => {'status': 'SUCCESSFUL'};

      final (status, json) = await call('GET', '/orders/$orderId');

      expect(status, 200);
      expect(json['status'], 'successful');
      expect(gateway.requests.last.path, ApiConstants.getPaymentStatus);
    });

    test('stays pending while the gateway does not know the payment', () async {
      final orderId = await startCheckout();
      gateway.handler = (_) => {
        'responseCode': '3',
        'responseMessage': 'Transaction not found',
      };

      expect((await call('GET', '/orders/$orderId')).$2['status'], 'pending');
    });
  });

  group('POST /webhooks/yallapay', () {
    String webhookBody(String orderId, String status) => jsonEncode({
      'clientReferenceId': orderId,
      'paymentReferenceId': 'yp-1',
      'status': status,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });

    test('a verified webhook updates the order, idempotently', () async {
      final orderId = await startCheckout();
      final body = webhookBody(orderId, 'SUCCESSFUL');
      final headers = signedHeaders(body);

      for (var i = 0; i < 2; i++) {
        final (status, _) = await call(
          'POST',
          '/webhooks/yallapay',
          body: body,
          headers: headers,
        );
        expect(status, 200);
      }

      final requestsBefore = gateway.requests.length;
      expect((await call('GET', '/orders/$orderId')).$2['status'], 'successful');
      expect(gateway.requests, hasLength(requestsBefore)); // no status call
    });

    test('a forged webhook is rejected and changes nothing', () async {
      final orderId = await startCheckout();
      final body = webhookBody(orderId, 'SUCCESSFUL');

      final (status, _) = await call(
        'POST',
        '/webhooks/yallapay',
        body: body,
        headers: {
          'YallaPay-Signature': '0' * 64,
          'YallaPay-TimeStamp': DateTime.now().millisecondsSinceEpoch
              .toString(),
        },
      );
      expect(status, 401);

      gateway.handler = (_) => {'responseCode': '3', 'responseMessage': 'x'};
      expect((await call('GET', '/orders/$orderId')).$2['status'], 'pending');
    });

    test('a signed but malformed body is a 400', () async {
      const body = '{"status":"SUCCESSFUL"}';

      final (status, _) = await call(
        'POST',
        '/webhooks/yallapay',
        body: body,
        headers: signedHeaders(body),
      );

      expect(status, 400);
    });
  });
}
