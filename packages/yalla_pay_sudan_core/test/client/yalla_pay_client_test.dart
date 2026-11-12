import 'package:dio/dio.dart';
import 'package:test/test.dart';
import 'package:yalla_pay_sudan_core/yalla_pay_sudan_core.dart';

import '../support/fake_http.dart';

void main() {
  late FakeAdapter adapter;
  late YallaPayClient client;

  YallaPayClient clientWith(YallaPayConfig config) =>
      YallaPayClient.withDio(config, fakeDio(adapter));

  setUp(() {
    adapter = FakeAdapter((_) => jsonResponse(successBody));
    client = clientWith(
      const YallaPayConfig(
        apiKey: 'test-token',
        webhookSecret: 'test-secret',
        retryDelay: Duration.zero,
      ),
    );
  });

  test('rejects an empty API key', () {
    expect(
      () => clientWith(const YallaPayConfig(apiKey: '')),
      throwsArgumentError,
    );
  });

  group('createPayment', () {
    test('validates before sending anything', () {
      const request = PaymentRequest(amount: 500, clientReferenceId: 'o-1');

      expect(() => client.createPayment(request), throwsArgumentError);
      expect(adapter.requests, isEmpty);
    });

    test('attaches the redirect URLs to the response', () async {
      final result = await client.createPayment(
        const PaymentRequest(
          amount: 5000,
          clientReferenceId: 'order-123',
          paymentSuccessfulRedirectUrl: 'https://shop.example/paid',
          paymentFailedRedirectUrl: 'https://shop.example/failed',
        ),
      );

      expect(result.paymentUrl, contains('test-id'));
      expect(result.successRedirectUrl, 'https://shop.example/paid');
      expect(result.failedRedirectUrl, 'https://shop.example/failed');
    });

    test('is never retried, even after a timeout', () async {
      adapter.handler = (options) => throw DioException(
        requestOptions: options,
        type: DioExceptionType.receiveTimeout,
      );

      await expectLater(
        client.createPayment(
          const PaymentRequest(amount: 5000, clientReferenceId: 'order-123'),
        ),
        throwsA(isA<NetworkException>()),
      );
      expect(adapter.requests, hasLength(1));
    });
  });

  group('createSubscription', () {
    test('validates before sending anything', () {
      const request = SubscriptionRequest(
        amount: 5000,
        clientReferenceId: ' ',
        subscriptionConfiguration: SubscriptionConfiguration(
          interval: SubscriptionInterval.month,
          intervalCycle: 1,
        ),
      );

      expect(() => client.createSubscription(request), throwsArgumentError);
      expect(adapter.requests, isEmpty);
    });

    test('returns the response', () async {
      final result = await client.createSubscription(
        const SubscriptionRequest(
          amount: 5000,
          clientReferenceId: 'sub-123',
          subscriptionConfiguration: SubscriptionConfiguration(
            interval: SubscriptionInterval.month,
            intervalCycle: 1,
          ),
        ),
      );

      expect(result.isSuccess, isTrue);
    });
  });

  group('getPaymentStatus', () {
    test('sends the date as YYYY-MM-DD', () async {
      adapter.handler = (_) => jsonResponse({'status': 'SUCCESSFUL'});

      await client.getPaymentStatus(
        clientReferenceId: 'order-123',
        transactionDate: DateTime(2025, 3, 7, 23, 59),
      );

      expect(adapter.requests.single.data, {
        'clientReferenceId': 'order-123',
        'transactionDate': '2025-03-07',
      });
    });

    test('retries network errors, then succeeds', () async {
      var calls = 0;
      adapter.handler = (options) {
        calls++;
        if (calls < 3) {
          throw DioException.connectionError(
            requestOptions: options,
            reason: 'offline',
          );
        }
        return jsonResponse({'status': 'SUCCESSFUL'});
      };

      final result = await client.getPaymentStatus(
        clientReferenceId: 'order-123',
        transactionDate: DateTime(2025, 3, 7),
      );

      expect(result.isSuccessful, isTrue);
      expect(calls, 3);
    });

    test('gives up after statusRetries', () async {
      adapter.handler = (options) => throw DioException(
        requestOptions: options,
        type: DioExceptionType.connectionTimeout,
      );

      await expectLater(
        client.getPaymentStatus(
          clientReferenceId: 'order-123',
          transactionDate: DateTime(2025, 3, 7),
        ),
        throwsA(isA<NetworkException>()),
      );
      expect(adapter.requests, hasLength(3)); // 1 try + 2 retries
    });

    test('does not retry gateway errors', () async {
      adapter.handler = (_) =>
          jsonResponse({'responseCode': '3', 'responseMessage': 'Not found'});

      await expectLater(
        client.getPaymentStatus(
          clientReferenceId: 'order-123',
          transactionDate: DateTime(2025, 3, 7),
        ),
        throwsA(isA<PaymentException>()),
      );
      expect(adapter.requests, hasLength(1));
    });

    test('rejects a blank reference', () {
      expect(
        () => client.getPaymentStatus(
          clientReferenceId: '',
          transactionDate: DateTime(2025),
        ),
        throwsArgumentError,
      );
    });
  });

  group('formatTransactionDate', () {
    test('pads month, day and year', () {
      expect(YallaPayClient.formatTransactionDate(DateTime(2026, 1, 2)), '2026-01-02');
      expect(YallaPayClient.formatTransactionDate(DateTime(999, 12, 31)), '0999-12-31');
    });
  });

  group('verifyWebhook', () {
    test('throws StateError without a webhook secret', () {
      final noSecret = clientWith(const YallaPayConfig(apiKey: 'test-token'));

      expect(
        () => noSecret.verifyWebhook(
          signature: 'sig',
          timestamp: '123',
          rawBody: '{}',
        ),
        throwsStateError,
      );
      expect(
        () => noSecret.verifyWebhookBytes(
          signature: 'sig',
          timestamp: '123',
          body: const [],
        ),
        throwsStateError,
      );
    });

    test('an empty webhook secret is rejected', () {
      expect(
        () => clientWith(const YallaPayConfig(apiKey: 'k', webhookSecret: '')),
        throwsArgumentError,
      );
    });
  });

  group('config', () {
    test('sandbox and live select the base URL', () {
      expect(
        const YallaPayConfig.sandbox(apiKey: 'k').baseUrl,
        ApiConstants.sandboxBaseUrl,
      );
      expect(
        const YallaPayConfig.live(apiKey: 'k').baseUrl,
        ApiConstants.defaultBaseUrl,
      );
    });

    test('logging is off by default', () {
      expect(const YallaPayConfig(apiKey: 'k').enableLogging, isFalse);
      expect(const YallaPayConfig.live(apiKey: 'k').enableLogging, isFalse);
      expect(const YallaPayConfig.sandbox(apiKey: 'k').enableLogging, isFalse);
    });

    test('toString redacts secrets', () {
      final text = const YallaPayConfig(
        apiKey: 'sk_live_secret',
        webhookSecret: 'whsec_secret',
      ).toString();

      expect(text, isNot(contains('sk_live_secret')));
      expect(text, isNot(contains('whsec_secret')));
    });
  });

  test('dispose closes the HTTP client', () {
    client.dispose();
    expect(adapter.closed, isTrue);
  });
}
