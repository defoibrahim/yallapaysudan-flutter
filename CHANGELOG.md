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
