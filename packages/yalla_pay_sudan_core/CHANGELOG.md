## 2.0.0

First release of `yalla_pay_sudan_core`: the API client, models, exceptions
and webhook verifier from `yalla_pay_sudan` 1.0.2, moved into a pure Dart
package with no Flutter dependency so they run on servers. The version
continues from `yalla_pay_sudan` 1.x. Changes compared with 1.0.2:

### Breaking

- `PaymentStatus.unknown` is new. Unrecognised gateway statuses map to it
  instead of throwing, and `WebhookPayload.rawStatus` /
  `PaymentStatusResponse.rawStatus` keep the original value. Exhaustive
  `switch` statements over `PaymentStatus` need a case for it.
- New exception types in the sealed `YallaPayException` hierarchy:
  `InvalidResponseException` (unreadable JSON, missing or mistyped fields) and
  `DuplicateReferenceException` (a `PaymentException` for a reused
  `clientReferenceId`). Exhaustive `switch` statements need the new case.
  Type errors and `FormatException`s from bad responses no longer escape.
- `NetworkException` now has `isTimeout`; `PaymentException` now has
  `statusCode`. HTTP errors are reported as `PaymentException` with the
  status code, timeouts and connection failures as `NetworkException`.
- `getPaymentStatus` takes `transactionDate` as a `DateTime` (sent as
  `YYYY-MM-DD`) and throws `PaymentException` when the gateway answers with an
  error envelope instead of a status.
- `PaymentRequest.amount` and `SubscriptionRequest.amount` are `num`.
  Validation rejects `NaN`, infinity, blank references and redirect URLs that
  are not absolute http(s) URLs. Whole amounts are sent as integers.
- `WebhookVerifier` rejects an empty secret, and `YallaPayClient` rejects an
  empty API key.
- `WebhookVerifier` timestamps more than the tolerance in the future are now
  reported as "outside the allowed window" (the message changed).

### Added

- `WebhookVerifier.verifyBytes` and `YallaPayClient.verifyWebhookBytes`, to
  verify the exact raw body bytes; `WebhookVerifier.clock` for tests.
- Network errors in `getPaymentStatus` are retried (`statusRetries`,
  `retryDelay`). Payment creation is never retried automatically.
- `PaymentRequest.minimumAmount` / `SubscriptionRequest.minimumAmount`,
  `ApiConstants.gatewayDomain`, `YallaPayClient.formatTransactionDate`.
- `YallaPayConfig.toString()` redacts the API key and webhook secret.
- Every public API element is documented, including the server-only
  guidance, idempotency and replay handling.

### Fixed

- Malformed, out-of-range and future webhook timestamps no longer throw
  `RangeError`; they fail verification.
- Responses with numeric codes or JSON sent as `text/plain` are read
  correctly.
- `PaymentResponse` equality now includes the redirect URLs.
- Tests: known-answer HMAC vectors computed with OpenSSL, tests for every
  error path, the interceptors (the token is never logged), retries and
  README samples (which are analyzed in CI).
