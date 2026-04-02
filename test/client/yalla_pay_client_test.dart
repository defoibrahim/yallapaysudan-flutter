import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:yalla_pay_sudan/yalla_pay_sudan.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio mockDio;
  late YallaPayClient client;

  final successResponse = {
    'responseCode': '0',
    'responseMessage': 'Success',
    'currentDate': '2025-06-22',
    'currentTime': '13:25:20',
    'paymentUrl': 'https://gateway.yallapaysudan.com/checkout/web/test-id',
  };

  setUp(() {
    mockDio = MockDio();
    client = YallaPayClient.withDio(
      const YallaPayConfig(
        apiKey: 'test-token',
        webhookSecret: 'test-secret',
      ),
      mockDio,
    );
  });

  group('YallaPayClient', () {
    group('createPayment', () {
      test('validates request before API call', () async {
        const request = PaymentRequest(
          amount: 500,
          clientReferenceId: 'order-123',
        );

        expect(
          () => client.createPayment(request),
          throwsArgumentError,
        );

        verifyNever(() => mockDio.post<Map<String, dynamic>>(
              any(),
              data: any(named: 'data'),
            ));
      });

      test('returns PaymentResponse on success', () async {
        when(() => mockDio.post<Map<String, dynamic>>(
              ApiConstants.generatePaymentLink,
              data: any(named: 'data'),
            )).thenAnswer((_) async => Response(
              data: successResponse,
              statusCode: 200,
              requestOptions:
                  RequestOptions(path: ApiConstants.generatePaymentLink),
            ));

        const request = PaymentRequest(
          amount: 5000,
          clientReferenceId: 'order-123',
        );

        final result = await client.createPayment(request);

        expect(result.isSuccess, true);
        expect(result.paymentUrl, contains('test-id'));
      });
    });

    group('createSubscription', () {
      test('validates request before API call', () async {
        const request = SubscriptionRequest(
          amount: 5000,
          clientReferenceId: '',
          subscriptionConfiguration: SubscriptionConfiguration(
            interval: SubscriptionInterval.month,
            intervalCycle: 1,
          ),
        );

        expect(
          () => client.createSubscription(request),
          throwsArgumentError,
        );
      });

      test('returns PaymentResponse on success', () async {
        when(() => mockDio.post<Map<String, dynamic>>(
              ApiConstants.generateSubscriptionPaymentLink,
              data: any(named: 'data'),
            )).thenAnswer((_) async => Response(
              data: successResponse,
              statusCode: 200,
              requestOptions: RequestOptions(
                path: ApiConstants.generateSubscriptionPaymentLink,
              ),
            ));

        const request = SubscriptionRequest(
          amount: 5000,
          clientReferenceId: 'sub-123',
          subscriptionConfiguration: SubscriptionConfiguration(
            interval: SubscriptionInterval.month,
            intervalCycle: 1,
          ),
        );

        final result = await client.createSubscription(request);

        expect(result.isSuccess, true);
      });
    });

    group('verifyWebhook', () {
      test('throws StateError when no webhook secret configured', () {
        final clientNoSecret = YallaPayClient.withDio(
          const YallaPayConfig(apiKey: 'test-token'),
          mockDio,
        );

        expect(
          () => clientNoSecret.verifyWebhook(
            signature: 'sig',
            timestamp: '123',
            rawBody: '{}',
          ),
          throwsStateError,
        );
      });
    });

    group('dispose', () {
      test('closes the Dio client', () {
        when(() => mockDio.close()).thenReturn(null);

        client.dispose();

        verify(() => mockDio.close()).called(1);
      });
    });
  });
}
