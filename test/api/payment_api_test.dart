import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:yalla_pay_sudan/src/api/api_constants.dart';
import 'package:yalla_pay_sudan/src/api/payment_api.dart';
import 'package:yalla_pay_sudan/yalla_pay_sudan.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio mockDio;
  late PaymentApi api;

  setUp(() {
    mockDio = MockDio();
    api = PaymentApi(mockDio);
  });

  setUpAll(() {
    registerFallbackValue(Options());
  });

  group('PaymentApi', () {
    group('generatePaymentLink', () {
      test('returns PaymentResponse on success', () async {
        final responseData = {
          'responseCode': '0',
          'responseMessage': 'Success',
          'currentDate': '2025-06-22',
          'currentTime': '13:25:20',
          'paymentUrl':
              'https://gateway.yallapaysudan.com/checkout/web/test-id',
        };

        when(() => mockDio.post<Map<String, dynamic>>(
              ApiConstants.generatePaymentLink,
              data: any(named: 'data'),
            )).thenAnswer((_) async => Response(
              data: responseData,
              statusCode: 200,
              requestOptions:
                  RequestOptions(path: ApiConstants.generatePaymentLink),
            ));

        const request = PaymentRequest(
          amount: 5000,
          clientReferenceId: 'order-123',
        );

        final result = await api.generatePaymentLink(request);

        expect(result.isSuccess, true);
        expect(result.paymentUrl, contains('test-id'));
        expect(result.responseMessage, 'Success');
      });

      test('throws PaymentException on API error', () async {
        final responseData = {
          'responseCode': '1',
          'responseMessage': 'Invalid amount',
          'currentDate': '2025-06-22',
          'currentTime': '13:25:20',
          'paymentUrl': '',
        };

        when(() => mockDio.post<Map<String, dynamic>>(
              ApiConstants.generatePaymentLink,
              data: any(named: 'data'),
            )).thenAnswer((_) async => Response(
              data: responseData,
              statusCode: 200,
              requestOptions:
                  RequestOptions(path: ApiConstants.generatePaymentLink),
            ));

        const request = PaymentRequest(
          amount: 5000,
          clientReferenceId: 'order-123',
        );

        expect(
          () => api.generatePaymentLink(request),
          throwsA(isA<PaymentException>().having(
            (e) => e.responseCode,
            'responseCode',
            '1',
          )),
        );
      });

      test('throws NetworkException on DioException', () async {
        when(() => mockDio.post<Map<String, dynamic>>(
              ApiConstants.generatePaymentLink,
              data: any(named: 'data'),
            )).thenThrow(DioException(
              requestOptions:
                  RequestOptions(path: ApiConstants.generatePaymentLink),
              message: 'Connection timeout',
            ));

        const request = PaymentRequest(
          amount: 5000,
          clientReferenceId: 'order-123',
        );

        expect(
          () => api.generatePaymentLink(request),
          throwsA(isA<NetworkException>().having(
            (e) => e.message,
            'message',
            contains('Connection timeout'),
          )),
        );
      });

      test('throws PaymentException on null response body', () async {
        when(() => mockDio.post<Map<String, dynamic>>(
              ApiConstants.generatePaymentLink,
              data: any(named: 'data'),
            )).thenAnswer((_) async => Response(
              data: null,
              statusCode: 200,
              requestOptions:
                  RequestOptions(path: ApiConstants.generatePaymentLink),
            ));

        const request = PaymentRequest(
          amount: 5000,
          clientReferenceId: 'order-123',
        );

        expect(
          () => api.generatePaymentLink(request),
          throwsA(isA<PaymentException>()),
        );
      });
    });

    group('generateSubscriptionLink', () {
      test('returns PaymentResponse on success', () async {
        final responseData = {
          'responseCode': '0',
          'responseMessage': 'Success',
          'currentDate': '2025-06-22',
          'currentTime': '13:25:20',
          'paymentUrl':
              'https://gateway.yallapaysudan.com/checkout/web/sub-id',
        };

        when(() => mockDio.post<Map<String, dynamic>>(
              ApiConstants.generateSubscriptionPaymentLink,
              data: any(named: 'data'),
            )).thenAnswer((_) async => Response(
              data: responseData,
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
            totalCycles: 12,
          ),
        );

        final result = await api.generateSubscriptionLink(request);

        expect(result.isSuccess, true);
        expect(result.paymentUrl, contains('sub-id'));
      });
    });
  });
}
