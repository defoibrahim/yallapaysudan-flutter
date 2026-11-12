import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:yalla_pay_sudan_core/yalla_pay_sudan_core.dart';

void main() {
  group('PaymentResponse', () {
    test('fromJson parses valid response', () {
      final json = {
        'responseCode': '0',
        'responseMessage': 'Success',
        'currentDate': '2025-06-22',
        'currentTime': '13:25:20',
        'paymentUrl': 'https://gateway.yallapaysudan.com/checkout/web/test-id',
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

    test('fromJson converts numeric fields to strings', () {
      final response = PaymentResponse.fromJson({'responseCode': 0});

      expect(response.responseCode, '0');
      expect(response.isSuccess, isTrue);
    });

    test('fromJson throws InvalidResponseException for unusable types', () {
      expect(
        () => PaymentResponse.fromJson({'paymentUrl': <String>[]}),
        throwsA(isA<InvalidResponseException>()),
      );
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
      expect(PaymentStatus.fromString('SUCCESSFUL'), PaymentStatus.successful);
      expect(PaymentStatus.fromString('FAILED'), PaymentStatus.failed);
      expect(PaymentStatus.fromString('CANCELLED'), PaymentStatus.cancelled);
    });

    test('fromString is case-insensitive', () {
      expect(PaymentStatus.fromString('successful'), PaymentStatus.successful);
    });

    test('fromString maps unknown values to unknown', () {
      expect(PaymentStatus.fromString('PENDING'), PaymentStatus.unknown);
      expect(PaymentStatus.fromString(''), PaymentStatus.unknown);
    });

    test('fromString parses every known status', () {
      expect(PaymentStatus.fromString('REVOKED'), PaymentStatus.revoked);
      expect(PaymentStatus.fromString(' expired '), PaymentStatus.expired);
    });
  });

  group('PaymentStatusResponse', () {
    test('keeps the raw status and parses numeric strings', () {
      final response = PaymentStatusResponse.fromJson({
        'status': 'ON_HOLD',
        'amount': '2500.5',
      });

      expect(response.status, PaymentStatus.unknown);
      expect(response.rawStatus, 'ON_HOLD');
      expect(response.amount, 2500.5);
      expect(response.clientReferenceId, '');
    });

    test('requires a status', () {
      expect(
        () => PaymentStatusResponse.fromJson({'amount': 1}),
        throwsA(isA<InvalidResponseException>()),
      );
    });

    test('rejects a non-numeric amount', () {
      expect(
        () => PaymentStatusResponse.fromJson({'status': 'FAILED', 'amount': 'a'}),
        throwsA(isA<InvalidResponseException>()),
      );
    });
  });

  group('WebhookPayload', () {
    final valid = {
      'clientReferenceId': 'order-1',
      'paymentReferenceId': 'yp-1',
      'status': 'SUCCESSFUL',
      'timestamp': 1719057920000,
    };

    test('parses a valid body', () {
      final payload = WebhookPayload.fromJson(valid);

      expect(payload.isSuccessful, isTrue);
      expect(payload.timestamp, 1719057920000);
      expect(payload.rawStatus, 'SUCCESSFUL');
    });

    test('accepts a numeric-string timestamp', () {
      final payload = WebhookPayload.fromJson({
        ...valid,
        'timestamp': '1719057920000',
      });

      expect(payload.timestamp, 1719057920000);
    });

    for (final key in ['clientReferenceId', 'paymentReferenceId', 'status', 'timestamp']) {
      test('requires $key', () {
        expect(
          () => WebhookPayload.fromJson({...valid}..remove(key)),
          throwsA(isA<InvalidResponseException>()),
        );
      });
    }

    test('rejects a fractional timestamp', () {
      expect(
        () => WebhookPayload.fromJson({...valid, 'timestamp': 1.5}),
        throwsA(isA<InvalidResponseException>()),
      );
    });
  });
}
