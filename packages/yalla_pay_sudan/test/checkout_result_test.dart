import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_pay_sudan/yalla_pay_sudan.dart';

void main() {
  group('CheckoutResult', () {
    test('status getters', () {
      const result = CheckoutResult(status: PaymentStatus.successful);
      expect(result.isSuccessful, isTrue);
      expect(result.isFailed, isFalse);
      expect(result.isCancelled, isFalse);
    });

    test('equality', () {
      expect(
        const CheckoutResult(status: PaymentStatus.failed, redirectUrl: 'x'),
        const CheckoutResult(status: PaymentStatus.failed, redirectUrl: 'x'),
      );
    });
  });
}
