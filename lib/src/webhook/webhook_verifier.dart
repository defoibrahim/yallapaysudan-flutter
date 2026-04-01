import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../exceptions/yalla_pay_exception.dart';
import '../models/webhook_payload.dart';

/// Verifies YallaPaySudan webhook signatures using HMAC-SHA256.
class WebhookVerifier {
  /// The webhook secret key from the merchant dashboard.
  final String secret;

  /// Maximum allowed age for webhook timestamps.
  final Duration timestampTolerance;

  /// Pre-computed HMAC instance (avoids re-encoding the key on every call).
  final Hmac _hmac;

  WebhookVerifier({
    required this.secret,
    this.timestampTolerance = const Duration(minutes: 5),
  }) : _hmac = Hmac(sha256, utf8.encode(secret));

  /// Verifies the webhook signature and parses the payload.
  ///
  /// Throws [InvalidSignatureException] if the signature is invalid
  /// or the timestamp is too old.
  WebhookPayload verify({
    required String signature,
    required String timestamp,
    required String rawBody,
  }) {
    _verifyTimestamp(timestamp);
    _verifySignature(signature, timestamp, rawBody);

    final json = jsonDecode(rawBody) as Map<String, dynamic>;
    return WebhookPayload.fromJson(json);
  }

  void _verifyTimestamp(String timestamp) {
    final timestampMs = int.tryParse(timestamp);
    if (timestampMs == null) {
      throw const InvalidSignatureException(
        'Invalid webhook timestamp format.',
      );
    }

    final webhookTime = DateTime.fromMillisecondsSinceEpoch(timestampMs);
    final now = DateTime.now();
    final difference = now.difference(webhookTime).abs();

    if (difference > timestampTolerance) {
      throw const InvalidSignatureException(
        'Webhook timestamp is too old — possible replay attack.',
      );
    }
  }

  void _verifySignature(
    String signature,
    String timestamp,
    String rawBody,
  ) {
    final message = utf8.encode('$timestamp.$rawBody');
    final digest = _hmac.convert(message);
    final computed = digest.toString();

    if (!_constantTimeEquals(computed, signature.toLowerCase())) {
      throw const InvalidSignatureException();
    }
  }

  bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;

    var result = 0;
    for (var i = 0; i < a.length; i++) {
      result |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return result == 0;
  }
}
