import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../exceptions/yalla_pay_exception.dart';
import '../models/webhook_payload.dart';

/// Verifies YallaPaySudan webhook signatures. **Server-side only.**
///
/// The signature is the lowercase hex HMAC-SHA256, keyed with the webhook
/// secret, of `"<timestamp>.<raw body>"`, where `<timestamp>` is the
/// `YallaPay-TimeStamp` header (Unix milliseconds) and the signature arrives
/// in the `YallaPay-Signature` header.
///
/// Verification checks, in order:
/// 1. the timestamp is an integer within [timestampTolerance] of now (in
///    either direction), which limits how long a captured request can be
///    replayed;
/// 2. the signature matches, compared in constant time;
/// 3. the body is a JSON object with the expected fields.
///
/// **Replays inside the window.** The timestamp check cannot stop the same
/// webhook from being delivered again within [timestampTolerance] (the
/// gateway itself retries deliveries). Make your handler idempotent: record
/// each processed `paymentReferenceId` and status, and ignore repeats.
///
/// **Use the raw body.** Verify the exact bytes you received, before any
/// JSON parsing or re-encoding: [verifyBytes] when your framework gives you
/// bytes, [verify] when it gives you the undecoded UTF-8 string.
class WebhookVerifier {
  /// The webhook secret from the merchant dashboard.
  final String secret;

  /// Maximum difference between the webhook timestamp and now.
  final Duration timestampTolerance;

  /// The clock used for the timestamp check. Defaults to [DateTime.now];
  /// replace it in tests.
  final DateTime Function() clock;

  final Hmac _hmac;

  /// Creates a verifier for [secret].
  ///
  /// Throws [ArgumentError] if [secret] is empty, which would make every
  /// signature forgeable.
  WebhookVerifier({
    required this.secret,
    this.timestampTolerance = const Duration(minutes: 5),
    DateTime Function()? clock,
  }) : clock = clock ?? DateTime.now,
       _hmac = Hmac(sha256, utf8.encode(_checkSecret(secret)));

  static String _checkSecret(String secret) {
    if (secret.isEmpty) {
      throw ArgumentError.value(secret, 'secret', 'Must not be empty');
    }
    return secret;
  }

  /// Verifies a webhook whose body you have as an (undecoded) string and
  /// returns its payload.
  ///
  /// Throws [InvalidSignatureException] if the timestamp or signature check
  /// fails, and [InvalidResponseException] if a correctly signed body is not
  /// a valid payload.
  WebhookPayload verify({
    required String signature,
    required String timestamp,
    required String rawBody,
  }) => verifyBytes(
    signature: signature,
    timestamp: timestamp,
    body: utf8.encode(rawBody),
  );

  /// Verifies a webhook from the exact body bytes received and returns its
  /// payload.
  ///
  /// Throws [InvalidSignatureException] if the timestamp or signature check
  /// fails, and [InvalidResponseException] if a correctly signed body is not
  /// a valid payload.
  WebhookPayload verifyBytes({
    required String signature,
    required String timestamp,
    required List<int> body,
  }) {
    _verifyTimestamp(timestamp);
    _verifySignature(signature, timestamp, body);
    return _parse(body);
  }

  void _verifyTimestamp(String timestamp) {
    final timestampMs = int.tryParse(timestamp.trim());
    // Anything outside year 1970..5138 is malformed; this also keeps the
    // arithmetic below far from integer overflow.
    if (timestampMs == null ||
        timestampMs < 0 ||
        timestampMs > 99999999999999) {
      throw const InvalidSignatureException(
        'Invalid webhook timestamp format.',
      );
    }
    final ageMs = clock().millisecondsSinceEpoch - timestampMs;
    if (ageMs.abs() > timestampTolerance.inMilliseconds) {
      throw const InvalidSignatureException(
        'Webhook timestamp is outside the allowed window; possible replay.',
      );
    }
  }

  void _verifySignature(String signature, String timestamp, List<int> body) {
    final message = [...utf8.encode('${timestamp.trim()}.'), ...body];
    final computed = _hmac.convert(message).toString();
    if (!_constantTimeEquals(computed, signature.trim().toLowerCase())) {
      throw const InvalidSignatureException();
    }
  }

  WebhookPayload _parse(List<int> body) {
    final Object? decoded;
    try {
      decoded = jsonDecode(utf8.decode(body));
    } on FormatException {
      throw const InvalidResponseException(
        'Webhook body is not valid UTF-8 JSON.',
      );
    }
    if (decoded is! Map<String, dynamic>) {
      throw InvalidResponseException(
        'Webhook body is not a JSON object.',
        rawResponse: decoded,
      );
    }
    return WebhookPayload.fromJson(decoded);
  }

  /// Compares in time that depends only on the length, so the comparison
  /// does not reveal how many leading characters matched.
  static bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    var result = 0;
    for (var i = 0; i < a.length; i++) {
      result |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return result == 0;
  }
}
