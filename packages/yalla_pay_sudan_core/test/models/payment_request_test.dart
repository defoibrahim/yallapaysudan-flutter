import 'package:test/test.dart';
import 'package:yalla_pay_sudan_core/yalla_pay_sudan_core.dart';

void main() {
  group('PaymentRequest', () {
    test('toJson includes required fields', () {
      const request = PaymentRequest(
        amount: 5000,
        clientReferenceId: 'order-123',
      );

      final json = request.toJson();

      expect(json['amount'], 5000);
      expect(json['clientReferenceId'], 'order-123');
      expect(json['commissionPaidByCustomer'], false);
      expect(json.containsKey('description'), false);
    });

    test('toJson includes optional fields when set', () {
      const request = PaymentRequest(
        amount: 5000,
        clientReferenceId: 'order-123',
        description: 'Test payment',
        paymentSuccessfulRedirectUrl: 'https://example.com/success',
        paymentFailedRedirectUrl: 'https://example.com/failed',
        commissionPaidByCustomer: true,
      );

      final json = request.toJson();

      expect(json['description'], 'Test payment');
      expect(
        json['paymentSuccessfulRedirectUrl'],
        'https://example.com/success',
      );
      expect(json['paymentFailedRedirectUrl'], 'https://example.com/failed');
      expect(json['commissionPaidByCustomer'], true);
    });

    test('validate throws on amount below 1000', () {
      const request = PaymentRequest(
        amount: 500,
        clientReferenceId: 'order-123',
      );

      expect(() => request.validate(), throwsArgumentError);
    });

    test('validate throws on empty clientReferenceId', () {
      const request = PaymentRequest(amount: 5000, clientReferenceId: '');

      expect(() => request.validate(), throwsArgumentError);
    });

    test('validate passes for valid request', () {
      const request = PaymentRequest(
        amount: 1000,
        clientReferenceId: 'order-123',
      );

      expect(() => request.validate(), returnsNormally);
    });

    test('equality works correctly', () {
      const a = PaymentRequest(amount: 5000, clientReferenceId: 'order-1');
      const b = PaymentRequest(amount: 5000, clientReferenceId: 'order-1');
      const c = PaymentRequest(amount: 6000, clientReferenceId: 'order-1');

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });

    test('validate rejects non-finite amounts', () {
      for (final amount in [double.nan, double.infinity]) {
        expect(
          () => PaymentRequest(
            amount: amount,
            clientReferenceId: 'order-1',
          ).validate(),
          throwsArgumentError,
        );
      }
    });

    test('validate rejects a blank reference', () {
      expect(
        () => const PaymentRequest(
          amount: 5000,
          clientReferenceId: '   ',
        ).validate(),
        throwsArgumentError,
      );
    });

    test('validate rejects relative or non-http redirect URLs', () {
      for (final url in ['/success', 'myapp://paid', 'example.com/ok']) {
        expect(
          () => PaymentRequest(
            amount: 5000,
            clientReferenceId: 'order-1',
            paymentSuccessfulRedirectUrl: url,
          ).validate(),
          throwsArgumentError,
          reason: url,
        );
      }
    });

    test('whole amounts are sent as integers, fractions kept', () {
      expect(
        const PaymentRequest(amount: 5000.0, clientReferenceId: 'o').toJson()['amount'],
        isA<int>(),
      );
      expect(
        const PaymentRequest(amount: 1500.5, clientReferenceId: 'o').toJson()['amount'],
        1500.5,
      );
    });

    test('minimumAmount is the gateway minimum', () {
      expect(PaymentRequest.minimumAmount, 1000);
      expect(
        () => const PaymentRequest(amount: 999.99, clientReferenceId: 'o').validate(),
        throwsArgumentError,
      );
      expect(
        () => const PaymentRequest(amount: 1000, clientReferenceId: 'o').validate(),
        returnsNormally,
      );
    });
  });
}
