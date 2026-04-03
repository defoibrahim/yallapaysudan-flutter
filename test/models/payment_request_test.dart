import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_pay_sudan/yalla_pay_sudan.dart';

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
  });
}
