## 2.0.0

- **BREAKING:** The API client (`YallaPayClient`, `YallaPayConfig`, requests,
  `PaymentApi`, exceptions) and `WebhookVerifier` moved to the new pure Dart
  package [`yalla_pay_sudan_core`](https://pub.dev/packages/yalla_pay_sudan_core).
  They belong on your server: the auth token and webhook secret must not be
  shipped in an app. This package keeps the in-app checkout
  (`YallaPayCheckoutWebView`, `CheckoutResult`) and re-exports `PaymentStatus`
  and `PaymentResponse`.
- **BREAKING:** Requires Dart 3.12 / Flutter 3.44 or newer and uses
  `package:material_ui` (Flutter 3.50 deprecates `package:flutter/material.dart`).
- Supports `equatable` 3.x.

## 1.0.2

- Refactor PaymentApi: extract `_parsePaymentResponse` and `_mapDioException`
- Use redirecting constructors for `YallaPayConfig.sandbox`/`.live`
- Deduplicate `YallaPayClient` constructors via delegation
- Cache HMAC key in `WebhookVerifier` constructor for better performance
- Replace `print` with `dart:developer log` in logging interceptor
- Update `example.dart` with complete payment flow for pub.dev
- Code quality cleanup and linter fixes

## 1.0.1

- Add `getPaymentStatus` endpoint with `transactionDate` support
- Add `PaymentStatus.revoked` and `PaymentStatus.expired` statuses
- Add `YallaPayConfig.sandbox()` and `YallaPayConfig.live()` named constructors
- Add `PaymentResponse.copyWith()` for attaching redirect URLs
- Export `ApiConstants` for `sandboxBaseUrl` / `defaultBaseUrl` access
- Merge `CheckoutStatus` into `PaymentStatus` (simpler API)
- Fix screenshots not rendering on pub.dev

## 1.0.0

- One-time payment link generation
- Subscription payment link generation with interval configuration
- In-app WebView checkout with automatic redirect detection
- Webhook signature verification (HMAC-SHA256) with replay attack protection
- Sealed exception hierarchy (PaymentException, NetworkException, InvalidSignatureException)
- Sandbox and production environment support
