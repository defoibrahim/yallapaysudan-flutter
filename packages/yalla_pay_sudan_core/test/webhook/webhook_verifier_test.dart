import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:test/test.dart';
import 'package:yalla_pay_sudan_core/yalla_pay_sudan_core.dart';

void main() {
  // Known-answer vectors computed outside Dart with OpenSSL:
  //   printf '%s' "$ts.$body" | openssl dgst -sha256 -hmac "$secret"
  // They pin the scheme HMAC-SHA256(secret, "<timestamp>.<raw body>") as lowercase
  // hex. (The gateway does not publish test vectors; this checks that the
  // implementation matches the documented scheme byte for byte.)
  const katSecret = 'whsec_kat_7f3a9c';
  const katTimestamp = '1719057920000';
  const katBody =
      '{"clientReferenceId":"order-123","paymentReferenceId":"yp-ref-456",'
      '"status":"SUCCESSFUL","timestamp":1719057920000}';
  const katSignature =
      '18803755d88d9e46f17a1537a1fa11846e1a35972f7b9a4091b6f15b59ca9169';
  // Same secret and timestamp; the body contains Arabic text (multi-byte UTF-8).
  const katUtf8Body =
      '{"clientReferenceId":"طلب-7","paymentReferenceId":"yp-ref-9",'
      '"status":"FAILED","timestamp":1719057920000}';
  const katUtf8Signature =
      '1b1b9d2917adb937ebdf96e6e862b82385c1ee6700e05c3b1984d0dc62c120b3';

  final katTime = DateTime.fromMillisecondsSinceEpoch(int.parse(katTimestamp));

  WebhookVerifier verifierAt(
    DateTime now, {
    Duration tolerance = const Duration(minutes: 5),
  }) => WebhookVerifier(
    secret: katSecret,
    timestampTolerance: tolerance,
    clock: () => now,
  );

  group('known-answer vectors', () {
    test('ASCII body', () {
      final payload = verifierAt(katTime).verify(
        signature: katSignature,
        timestamp: katTimestamp,
        rawBody: katBody,
      );

      expect(payload.clientReferenceId, 'order-123');
      expect(payload.paymentReferenceId, 'yp-ref-456');
      expect(payload.isSuccessful, isTrue);
      expect(payload.timestamp, 1719057920000);
    });

    test('UTF-8 body as a string and as bytes', () {
      final verifier = verifierAt(katTime);

      final fromString = verifier.verify(
        signature: katUtf8Signature,
        timestamp: katTimestamp,
        rawBody: katUtf8Body,
      );
      final fromBytes = verifier.verifyBytes(
        signature: katUtf8Signature,
        timestamp: katTimestamp,
        body: utf8.encode(katUtf8Body),
      );

      expect(fromString.clientReferenceId, 'طلب-7');
      expect(fromBytes, fromString);
      expect(fromBytes.isFailed, isTrue);
    });

    test('uppercase hex and surrounding whitespace are accepted', () {
      final payload = verifierAt(katTime).verify(
        signature: ' ${katSignature.toUpperCase()} ',
        timestamp: ' $katTimestamp ',
        rawBody: katBody,
      );

      expect(payload.isSuccessful, isTrue);
    });
  });

  group('signature', () {
    test('a changed body is rejected', () {
      expect(
        () => verifierAt(katTime).verify(
          signature: katSignature,
          timestamp: katTimestamp,
          rawBody: katBody.replaceFirst('SUCCESSFUL', 'FAILED'),
        ),
        throwsA(isA<InvalidSignatureException>()),
      );
    });

    test('re-encoded JSON (different bytes) is rejected', () {
      final reencoded = const JsonEncoder.withIndent(' ').convert(
        jsonDecode(katBody),
      );

      expect(
        () => verifierAt(katTime).verify(
          signature: katSignature,
          timestamp: katTimestamp,
          rawBody: reencoded,
        ),
        throwsA(isA<InvalidSignatureException>()),
      );
    });

    test('a different secret is rejected', () {
      final verifier = WebhookVerifier(
        secret: 'another-secret',
        clock: () => katTime,
      );

      expect(
        () => verifier.verify(
          signature: katSignature,
          timestamp: katTimestamp,
          rawBody: katBody,
        ),
        throwsA(isA<InvalidSignatureException>()),
      );
    });

    test('a truncated or garbage signature is rejected', () {
      for (final signature in ['', 'abc', katSignature.substring(1), 'x' * 64]) {
        expect(
          () => verifierAt(katTime).verify(
            signature: signature,
            timestamp: katTimestamp,
            rawBody: katBody,
          ),
          throwsA(isA<InvalidSignatureException>()),
          reason: signature,
        );
      }
    });

    test('the signed timestamp must match the header', () {
      // Signature is over katTimestamp; a different header value must fail
      // even though it is inside the time window.
      expect(
        () => verifierAt(katTime).verify(
          signature: katSignature,
          timestamp: '1719057920001',
          rawBody: katBody,
        ),
        throwsA(isA<InvalidSignatureException>()),
      );
    });
  });

  group('timestamp window', () {
    test('accepts just inside the tolerance, in both directions', () {
      for (final offset in [
        const Duration(minutes: 4, seconds: 59),
        -const Duration(minutes: 4, seconds: 59),
      ]) {
        expect(
          () => verifierAt(katTime.add(offset)).verify(
            signature: katSignature,
            timestamp: katTimestamp,
            rawBody: katBody,
          ),
          returnsNormally,
        );
      }
    });

    test('rejects old and future timestamps outside the tolerance', () {
      for (final offset in [
        const Duration(minutes: 5, milliseconds: 1),
        -const Duration(minutes: 5, milliseconds: 1),
      ]) {
        expect(
          () => verifierAt(katTime.add(offset)).verify(
            signature: katSignature,
            timestamp: katTimestamp,
            rawBody: katBody,
          ),
          throwsA(
            isA<InvalidSignatureException>().having(
              (e) => e.message,
              'message',
              contains('outside the allowed window'),
            ),
          ),
        );
      }
    });

    test('custom tolerance is respected', () {
      expect(
        () => verifierAt(
          katTime.add(const Duration(minutes: 1)),
          tolerance: const Duration(seconds: 30),
        ).verify(
          signature: katSignature,
          timestamp: katTimestamp,
          rawBody: katBody,
        ),
        throwsA(isA<InvalidSignatureException>()),
      );
    });

    test('malformed or out-of-range timestamps are rejected cleanly', () {
      for (final timestamp in [
        'not-a-number',
        '',
        '-1',
        '1.5',
        '99999999999999999',
        '9223372036854775807',
      ]) {
        expect(
          () => verifierAt(katTime).verify(
            signature: katSignature,
            timestamp: timestamp,
            rawBody: katBody,
          ),
          throwsA(isA<InvalidSignatureException>()),
          reason: timestamp,
        );
      }
    });
  });

  group('payload', () {
    // Signs [body] with the documented scheme, whose implementation is pinned
    // by the known-answer vectors above.
    String sign(String body) => _hmacHex(katSecret, '$katTimestamp.$body');

    test('a correctly signed body that is not JSON', () {
      const body = 'not json';
      expect(
        () => verifierAt(katTime).verify(
          signature: sign(body),
          timestamp: katTimestamp,
          rawBody: body,
        ),
        throwsA(isA<InvalidResponseException>()),
      );
    });

    test('a correctly signed JSON array', () {
      const body = '[1, 2]';
      expect(
        () => verifierAt(katTime).verify(
          signature: sign(body),
          timestamp: katTimestamp,
          rawBody: body,
        ),
        throwsA(isA<InvalidResponseException>()),
      );
    });

    test('a correctly signed body with a missing field', () {
      const body = '{"clientReferenceId":"order-1","status":"SUCCESSFUL"}';
      expect(
        () => verifierAt(katTime).verify(
          signature: sign(body),
          timestamp: katTimestamp,
          rawBody: body,
        ),
        throwsA(isA<InvalidResponseException>()),
      );
    });

    test('invalid UTF-8 bytes', () {
      final body = [0x7b, 0xff, 0x7d];
      expect(
        () => verifierAt(katTime).verifyBytes(
          signature: _hmacHexBytes(katSecret, [
            ...utf8.encode('$katTimestamp.'),
            ...body,
          ]),
          timestamp: katTimestamp,
          body: body,
        ),
        throwsA(isA<InvalidResponseException>()),
      );
    });

    test('an unknown status is kept, not thrown', () {
      const body =
          '{"clientReferenceId":"order-1","paymentReferenceId":"yp-1",'
          '"status":"PARTIALLY_REFUNDED","timestamp":1719057920000}';

      final payload = verifierAt(katTime).verify(
        signature: sign(body),
        timestamp: katTimestamp,
        rawBody: body,
      );

      expect(payload.status, PaymentStatus.unknown);
      expect(payload.rawStatus, 'PARTIALLY_REFUNDED');
    });
  });

  test('an empty secret is rejected', () {
    expect(() => WebhookVerifier(secret: ''), throwsArgumentError);
  });
}

String _hmacHex(String secret, String message) =>
    _hmacHexBytes(secret, utf8.encode(message));

String _hmacHexBytes(String secret, List<int> message) =>
    Hmac(sha256, utf8.encode(secret)).convert(message).toString();
