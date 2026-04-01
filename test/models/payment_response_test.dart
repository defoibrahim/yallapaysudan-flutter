import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_pay_sudan/yalla_pay_sudan.dart';

void main() {
  group('PaymentResponse', () {
    test('fromJson parses valid response', () {
      final json = {
        'responseCode': '0',
        'responseMessage': 'Success',
        'currentDate': '2025-06-22',
        'currentTime': '13:25:20',
        'paymentUrl':
            'https://gateway.yallapaysudan.com/checkout/web/test-id',
      };

      final response = PaymentResponse.fromJson(json);

      expect(response.responseCode, '0');
      expect(response.responseMessage, 'Success');
      expect(response.currentDate, '2025-06-22');
      expect(response.currentTime, '13:25:20');
      expect(response.paymentUrl, contains('test-id'));
      expect(response.isSuccess, true);
      expect(response.raw, json);
    });

    test('isSuccess returns false for non-zero responseCode', () {
      final response = PaymentResponse.fromJson({
        'responseCode': '1',
        'responseMessage': 'Error',
        'currentDate': '2025-06-22',
        'currentTime': '13:25:20',
        'paymentUrl': '',
      });

      expect(response.isSuccess, false);
    });

    test('fromJson handles missing fields gracefully', () {
      final response = PaymentResponse.fromJson({});

      expect(response.responseCode, '');
      expect(response.responseMessage, '');
      expect(response.paymentUrl, '');
    });

    test('fromJson parses fixture file', () {
      final file = File('test/fixtures/payment_response.json');
      final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      final response = PaymentResponse.fromJson(json);

      expect(response.isSuccess, true);
      expect(response.paymentUrl, isNotEmpty);
    });

    test('equality works correctly', () {
      final json = {
        'responseCode': '0',
        'responseMessage': 'Success',
        'currentDate': '2025-06-22',
        'currentTime': '13:25:20',
        'paymentUrl': 'https://example.com/pay',
      };

      final a = PaymentResponse.fromJson(json);
      final b = PaymentResponse.fromJson(json);

      expect(a, equals(b));
    });
  });

  group('PaymentStatus', () {
    test('fromString parses valid statuses', () {
      expect(
        PaymentStatus.fromString('SUCCESSFUL'),
        PaymentStatus.successful,
      );
      expect(PaymentStatus.fromString('FAILED'), PaymentStatus.failed);
      expect(
        PaymentStatus.fromString('CANCELLED'),
        PaymentStatus.cancelled,
      );
    });

    test('fromString is case-insensitive', () {
      expect(
        PaymentStatus.fromString('successful'),
        PaymentStatus.successful,
      );
    });

    test('fromString throws on unknown status', () {
      expect(() => PaymentStatus.fromString('PENDING'), throwsArgumentError);
    });
  });
}
