## 2.0.0

This release fixes security problems in 1.x. Upgrade, and move payment
creation to your server.

### Breaking

- **The API client moved to the server.** `YallaPayClient`, `YallaPayConfig`,
  the request models, `PaymentApi`, the exceptions and `WebhookVerifier` are
  now in the pure Dart package
  [`yalla_pay_sudan_core`](https://pub.dev/packages/yalla_pay_sudan_core).
  1.x encouraged putting the merchant auth token (and webhook secret) in the
  app, where anyone can extract them. This package keeps only the in-app
  checkout and re-exports `PaymentStatus` and `PaymentResponse`.
- `YallaPayCheckoutWebView` and `show()`: `successUrlPattern` /
  `failedUrlPattern` are now `successUrl` / `failedUrl`. They're required,
  and they match exactly (scheme, host, port and path; query and fragment
  ignored) instead of by substring, which any page could spoof.
- `show()` returns `Future<CheckoutResult>` and completes with
  `PaymentStatus.cancelled` when the page is closed. It throws `ArgumentError`
  when no payment URL or redirect URL is available; in 1.x a release build
  crashed on a null check.
- `errorWidgetBuilder(String)` is replaced by
  `errorBuilder(context, message, retry)`.
- `PaymentStatus.unknown` is new (see `yalla_pay_sudan_core`).
- Requires Dart 3.12 / Flutter 3.44 and uses `package:material_ui`
  (Flutter 3.50 deprecates `package:flutter/material.dart`).

### Security

- Navigation allow-list: top-level pages must be `https` on the gateway's
  domain or `allowedHosts`. Other hosts, `http` and app schemes are blocked
  and reported through `onNavigationBlocked`. The payment URL itself must
  pass the same check.
- Frames may load `https` content but never end the checkout.
- `CheckoutResult` is documented as a UI hint, not proof of payment.

### Fixed

- The end of the checkout is also detected from `onPageStarted` and
  `onUrlChange` (POST redirects on Android skip `onNavigationRequest`).
- Failed sub-resources (`isForMainFrame == false`) no longer replace the page
  with the error view. The default error view has a **Try again** button.
- Supports `equatable` 3.x.

### Docs and example

- Every public API element is documented, and the README samples are
  compiled in CI.
- The example app no longer bundles an auth token: it calls a reference
  Shelf backend (`example/server`) built on `yalla_pay_sudan_core`, and asks
  it for the confirmed order status. The example has iOS and macOS folders
  (with the `network.client` entitlement) and the `INTERNET` permission in
  release builds.

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
