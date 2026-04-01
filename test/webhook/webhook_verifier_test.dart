import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_pay_sudan/yalla_pay_sudan.dart';

void main() {
  const secret = 'test-secret-key';
  final verifier = WebhookVerifier(secret: secret);

  String generateSignature(String timestamp, String body) {
    final key = utf8.encode(secret);
    final message = utf8.encode('$timestamp.$body');
    final hmacSha256 = Hmac(sha256, key);
    return hmacSha256.convert(message).toString();
  }

  group('WebhookVerifier', () {
    test('accepts valid signature within tolerance', () {
      final timestamp =
          DateTime.now().millisecondsSinceEpoch.toString();
      final body = jsonEncode({
        'clientReferenceId': 'order-123',
        'paymentReferenceId': 'yp-ref-456',
        'status': 'SUCCESSFUL',
        'timestamp': int.parse(timestamp),
      });
      final signature = generateSignature(timestamp, body);

      final payload = verifier.verify(
        signature: signature,
        timestamp: timestamp,
        rawBody: body,
      );

      expect(payload.clientReferenceId, 'order-123');
      expect(payload.paymentReferenceId, 'yp-ref-456');
      expect(payload.isSuccessful, true);
      expect(payload.isFailed, false);
      expect(payload.isCancelled, false);
    });

    test('rejects invalid signature', () {
      final timestamp =
          DateTime.now().millisecondsSinceEpoch.toString();
      final body = jsonEncode({
        'clientReferenceId': 'order-123',
        'paymentReferenceId': 'yp-ref-456',
        'status': 'SUCCESSFUL',
        'timestamp': int.parse(timestamp),
      });

      expect(
        () => verifier.verify(
          signature: 'invalid-signature',
          timestamp: timestamp,
          rawBody: body,
        ),
        throwsA(isA<InvalidSignatureException>()),
      );
    });

    test('rejects expired timestamp', () {
      final oldTimestamp = DateTime.now()
          .subtract(const Duration(minutes: 10))
          .millisecondsSinceEpoch
          .toString();
      final body = jsonEncode({
        'clientReferenceId': 'order-123',
        'paymentReferenceId': 'yp-ref-456',
        'status': 'SUCCESSFUL',
        'timestamp': int.parse(oldTimestamp),
      });
      final signature = generateSignature(oldTimestamp, body);

      expect(
        () => verifier.verify(
          signature: signature,
          timestamp: oldTimestamp,
          rawBody: body,
        ),
        throwsA(isA<InvalidSignatureException>().having(
          (e) => e.message,
          'message',
          contains('too old'),
        )),
      );
    });

    test('rejects invalid timestamp format', () {
      final body = jsonEncode({
        'clientReferenceId': 'order-123',
        'paymentReferenceId': 'yp-ref-456',
        'status': 'SUCCESSFUL',
        'timestamp': 0,
      });

      expect(
        () => verifier.verify(
          signature: 'any',
          timestamp: 'not-a-number',
          rawBody: body,
        ),
        throwsA(isA<InvalidSignatureException>()),
      );
    });

    test('accepts timestamp at exact boundary', () {
      final boundaryTimestamp = DateTime.now()
          .subtract(const Duration(minutes: 4, seconds: 59))
          .millisecondsSinceEpoch
          .toString();
      final body = jsonEncode({
        'clientReferenceId': 'order-123',
        'paymentReferenceId': 'yp-ref-456',
        'status': 'FAILED',
        'timestamp': int.parse(boundaryTimestamp),
      });
      final signature = generateSignature(boundaryTimestamp, body);

      final payload = verifier.verify(
        signature: signature,
        timestamp: boundaryTimestamp,
        rawBody: body,
      );

      expect(payload.isFailed, true);
    });

    test('parses cancelled status', () {
      final timestamp =
          DateTime.now().millisecondsSinceEpoch.toString();
      final body = jsonEncode({
        'clientReferenceId': 'order-789',
        'paymentReferenceId': 'yp-ref-012',
        'status': 'CANCELLED',
        'timestamp': int.parse(timestamp),
      });
      final signature = generateSignature(timestamp, body);

      final payload = verifier.verify(
        signature: signature,
        timestamp: timestamp,
        rawBody: body,
      );

      expect(payload.isCancelled, true);
      expect(payload.clientReferenceId, 'order-789');
    });

    test('custom tolerance is respected', () {
      final strictVerifier = WebhookVerifier(
        secret: secret,
        timestampTolerance: Duration(seconds: 30),
      );

      final oldTimestamp = DateTime.now()
          .subtract(const Duration(minutes: 1))
          .millisecondsSinceEpoch
          .toString();
      final body = jsonEncode({
        'clientReferenceId': 'order-123',
        'paymentReferenceId': 'yp-ref-456',
        'status': 'SUCCESSFUL',
        'timestamp': int.parse(oldTimestamp),
      });
      final signature = generateSignature(oldTimestamp, body);

      expect(
        () => strictVerifier.verify(
          signature: signature,
          timestamp: oldTimestamp,
          rawBody: body,
        ),
        throwsA(isA<InvalidSignatureException>()),
      );
    });
  });
}
