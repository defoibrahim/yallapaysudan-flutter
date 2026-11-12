import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// A checkout started by the backend: everything the app needs, and nothing
/// secret.
class CheckoutSession {
  /// Creates a session.
  const CheckoutSession({
    required this.orderId,
    required this.paymentUrl,
    required this.successUrl,
    required this.failedUrl,
  });

  /// Reads the backend's `POST /checkout` response.
  factory CheckoutSession.fromJson(Map<String, dynamic> json) =>
      CheckoutSession(
        orderId: json['orderId'] as String,
        paymentUrl: json['paymentUrl'] as String,
        successUrl: json['successUrl'] as String,
        failedUrl: json['failedUrl'] as String,
      );

  /// The backend's order ID (also the gateway `clientReferenceId`).
  final String orderId;

  /// The hosted checkout page to open.
  final String paymentUrl;

  /// The success redirect URL the payment was created with.
  final String successUrl;

  /// The failure redirect URL the payment was created with.
  final String failedUrl;
}

/// Client for the reference backend in `example/server`.
///
/// The YallaPaySudan auth token and webhook secret live on that server; the
/// app only receives checkout URLs and order statuses.
class CheckoutBackend {
  /// Creates a client for [baseUrl], by default `CHECKOUT_BACKEND_URL` from
  /// `--dart-define`, or the development machine.
  CheckoutBackend({Uri? baseUrl, http.Client? httpClient})
    : baseUrl = baseUrl ?? _defaultBaseUrl(),
      _http = httpClient ?? http.Client();

  /// Where the backend runs.
  final Uri baseUrl;
  final http.Client _http;

  static Uri _defaultBaseUrl() {
    const configured = String.fromEnvironment('CHECKOUT_BACKEND_URL');
    if (configured.isNotEmpty) return Uri.parse(configured);
    // The Android emulator reaches the host machine at 10.0.2.2.
    final host = defaultTargetPlatform == TargetPlatform.android
        ? '10.0.2.2'
        : 'localhost';
    return Uri.parse('http://$host:8080');
  }

  /// Asks the backend to create a `payment` or `subscription` checkout.
  Future<CheckoutSession> startCheckout(String kind) async {
    final response = await _http.post(
      baseUrl.resolve('/checkout'),
      headers: {'content-type': 'application/json'},
      body: jsonEncode({'kind': kind}),
    );
    return CheckoutSession.fromJson(_decode(response));
  }

  /// The order status according to the backend (`successful`, `failed`,
  /// `cancelled`, `revoked`, `expired` or `pending`).
  Future<String> orderStatus(String orderId) async {
    final response = await _http.get(
      baseUrl.resolve('/orders/${Uri.encodeComponent(orderId)}'),
    );
    return _decode(response)['status'] as String;
  }

  Map<String, dynamic> _decode(http.Response response) {
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200) {
      throw Exception(body['error'] ?? 'Backend error ${response.statusCode}');
    }
    return body;
  }

  /// Closes the HTTP client.
  void close() => _http.close();
}
