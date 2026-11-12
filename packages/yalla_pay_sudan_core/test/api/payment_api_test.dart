import 'package:dio/dio.dart';
import 'package:test/test.dart';
import 'package:yalla_pay_sudan_core/src/api/payment_api.dart';
import 'package:yalla_pay_sudan_core/yalla_pay_sudan_core.dart';

import '../support/fake_http.dart';

void main() {
  late FakeAdapter adapter;
  late PaymentApi api;

  const request = PaymentRequest(amount: 5000, clientReferenceId: 'order-123');

  setUp(() {
    adapter = FakeAdapter((_) => jsonResponse(successBody));
    api = PaymentApi(fakeDio(adapter));
  });

  group('generatePaymentLink', () {
    test('posts the request and returns the response', () async {
      final result = await api.generatePaymentLink(request);

      expect(result.isSuccess, isTrue);
      expect(result.paymentUrl, contains('test-id'));
      expect(adapter.requests.single.path, ApiConstants.generatePaymentLink);
      expect(adapter.requests.single.data, request.toJson());
    });

    test('non-zero responseCode throws PaymentException', () {
      adapter.handler = (_) => jsonResponse({
        'responseCode': '1',
        'responseMessage': 'Invalid amount',
        'paymentUrl': '',
      });

      expect(
        api.generatePaymentLink(request),
        throwsA(
          isA<PaymentException>()
              .having((e) => e.responseCode, 'responseCode', '1')
              .having((e) => e.message, 'message', 'Invalid amount')
              .having((e) => e.statusCode, 'statusCode', isNull),
        ),
      );
    });

    test('numeric responseCode is read as a string', () async {
      adapter.handler = (_) =>
          jsonResponse({...successBody, 'responseCode': 0});

      final result = await api.generatePaymentLink(request);

      expect(result.responseCode, '0');
    });

    test('duplicate reference throws DuplicateReferenceException', () {
      adapter.handler = (_) => jsonResponse({
        'responseCode': '5',
        'responseMessage': 'Duplicate client reference ID',
      });

      expect(
        api.generatePaymentLink(request),
        throwsA(
          isA<DuplicateReferenceException>().having(
            (e) => e.responseCode,
            'responseCode',
            '5',
          ),
        ),
      );
    });

    test('duplicate reference on an HTTP error status', () {
      adapter.handler = (_) => jsonResponse({
        'responseMessage': 'duplicate clientReferenceId',
      }, status: 409);

      expect(
        api.generatePaymentLink(request),
        throwsA(
          isA<DuplicateReferenceException>()
              .having((e) => e.statusCode, 'statusCode', 409)
              .having((e) => e.responseCode, 'responseCode', '409'),
        ),
      );
    });

    test('HTTP error with a JSON envelope keeps code and message', () {
      adapter.handler = (_) => jsonResponse({
        'responseCode': 'AUTH_01',
        'responseMessage': 'Invalid token',
      }, status: 401);

      expect(
        api.generatePaymentLink(request),
        throwsA(
          isA<PaymentException>()
              .having((e) => e.statusCode, 'statusCode', 401)
              .having((e) => e.responseCode, 'responseCode', 'AUTH_01')
              .having((e) => e.message, 'message', 'Invalid token'),
        ),
      );
    });

    test('HTTP error with an HTML body throws PaymentException', () {
      adapter.handler = (_) => textResponse(
        '<html>Bad gateway</html>',
        status: 502,
        contentType: 'text/html',
      );

      expect(
        api.generatePaymentLink(request),
        throwsA(
          isA<PaymentException>()
              .having((e) => e.statusCode, 'statusCode', 502)
              .having((e) => e.responseCode, 'responseCode', '502')
              .having((e) => e.rawResponse, 'rawResponse', isNull),
        ),
      );
    });

    test('HTTP error with a badly typed envelope still maps', () {
      adapter.handler = (_) => jsonResponse({
        'responseCode': ['x'],
        'responseMessage': 'oops',
      }, status: 500);

      expect(
        api.generatePaymentLink(request),
        throwsA(
          isA<PaymentException>().having(
            (e) => e.responseCode,
            'responseCode',
            '500',
          ),
        ),
      );
    });

    test('JSON sent as text/plain is decoded', () async {
      adapter.handler = (_) => textResponse(
        '{"responseCode":"0","paymentUrl":"https://gateway.yallapaysudan.com/c/1"}',
      );

      final result = await api.generatePaymentLink(request);

      expect(result.paymentUrl, 'https://gateway.yallapaysudan.com/c/1');
    });

    test('non-JSON success body throws InvalidResponseException', () {
      adapter.handler = (_) => textResponse('OK');

      expect(
        api.generatePaymentLink(request),
        throwsA(isA<InvalidResponseException>()),
      );
    });

    test('empty body throws InvalidResponseException', () {
      adapter.handler = (_) => textResponse('');

      expect(
        api.generatePaymentLink(request),
        throwsA(isA<InvalidResponseException>()),
      );
    });

    test('success with an empty paymentUrl throws', () {
      adapter.handler = (_) => jsonResponse({...successBody, 'paymentUrl': ''});

      expect(
        api.generatePaymentLink(request),
        throwsA(isA<InvalidResponseException>()),
      );
    });

    test('success with a non-https paymentUrl throws', () {
      adapter.handler = (_) => jsonResponse({
        ...successBody,
        'paymentUrl': 'http://insecure.example/pay',
      });

      expect(
        api.generatePaymentLink(request),
        throwsA(isA<InvalidResponseException>()),
      );
    });

    test('field of the wrong type throws InvalidResponseException', () {
      adapter.handler = (_) => jsonResponse({...successBody, 'paymentUrl': {}});

      expect(
        api.generatePaymentLink(request),
        throwsA(isA<InvalidResponseException>()),
      );
    });

    for (final type in [
      DioExceptionType.connectionTimeout,
      DioExceptionType.sendTimeout,
      DioExceptionType.receiveTimeout,
    ]) {
      test('${type.name} throws NetworkException(isTimeout: true)', () {
        adapter.handler = (options) =>
            throw DioException(requestOptions: options, type: type);

        expect(
          api.generatePaymentLink(request),
          throwsA(
            isA<NetworkException>()
                .having((e) => e.isTimeout, 'isTimeout', isTrue)
                .having((e) => e.dioException?.type, 'type', type),
          ),
        );
      });
    }

    test('connection error throws NetworkException(isTimeout: false)', () {
      adapter.handler = (options) => throw DioException.connectionError(
        requestOptions: options,
        reason: 'Connection refused',
      );

      expect(
        api.generatePaymentLink(request),
        throwsA(
          isA<NetworkException>()
              .having((e) => e.isTimeout, 'isTimeout', isFalse)
              .having((e) => e.message, 'message', contains('refused')),
        ),
      );
    });
  });

  group('generateSubscriptionLink', () {
    test('posts to the subscription endpoint', () async {
      const subscription = SubscriptionRequest(
        amount: 3000,
        clientReferenceId: 'sub-1',
        subscriptionConfiguration: SubscriptionConfiguration(
          interval: SubscriptionInterval.month,
          intervalCycle: 1,
        ),
      );

      final result = await api.generateSubscriptionLink(subscription);

      expect(result.isSuccess, isTrue);
      expect(
        adapter.requests.single.path,
        ApiConstants.generateSubscriptionPaymentLink,
      );
    });
  });

  group('getPaymentStatus', () {
    Future<PaymentStatusResponse> status() => api.getPaymentStatus(
      clientReferenceId: 'order-123',
      transactionDate: '2025-12-05',
    );

    test('parses a successful status', () async {
      adapter.handler = (_) => jsonResponse({
        'clientReferenceId': 'order-123',
        'paymentReferenceId': 'yp-ref-456',
        'status': 'SUCCESSFUL',
        'amount': 5000,
        'paymentDate': '2025-12-05',
        'paymentTime': '13:15:02',
      });

      final result = await status();

      expect(result.isSuccessful, isTrue);
      expect(result.paymentReferenceId, 'yp-ref-456');
      expect(result.amount, 5000);
      expect(adapter.requests.single.data, {
        'clientReferenceId': 'order-123',
        'transactionDate': '2025-12-05',
      });
    });

    test('expired status', () async {
      adapter.handler = (_) =>
          jsonResponse({'status': 'EXPIRED', 'amount': '3000'});

      final result = await status();

      expect(result.status, PaymentStatus.expired);
      expect(result.amount, 3000);
    });

    test('an unknown status is kept, not thrown', () async {
      adapter.handler = (_) => jsonResponse({'status': 'PENDING_REVIEW'});

      final result = await status();

      expect(result.status, PaymentStatus.unknown);
      expect(result.rawStatus, 'PENDING_REVIEW');
      expect(result.isSuccessful, isFalse);
    });

    test('error envelope throws PaymentException', () {
      adapter.handler = (_) => jsonResponse({
        'responseCode': '3',
        'responseMessage': 'Transaction not found',
      });

      expect(
        status(),
        throwsA(
          isA<PaymentException>()
              .having((e) => e.responseCode, 'responseCode', '3')
              .having((e) => e.message, 'message', 'Transaction not found'),
        ),
      );
    });

    test('responseCode "0" with a status parses normally', () async {
      adapter.handler = (_) =>
          jsonResponse({'responseCode': '0', 'status': 'FAILED'});

      expect((await status()).status, PaymentStatus.failed);
    });

    test('missing status throws InvalidResponseException', () {
      adapter.handler = (_) => jsonResponse({'clientReferenceId': 'order-123'});

      expect(status(), throwsA(isA<InvalidResponseException>()));
    });
  });
}
