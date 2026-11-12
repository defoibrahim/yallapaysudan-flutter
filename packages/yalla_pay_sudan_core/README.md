# yalla_pay_sudan_core

Pure Dart client for the [YallaPaySudan](https://yallapaysudan.com) payment gateway, for **servers**. It creates one-time payment and subscription links, checks payment status and verifies webhook signatures. There's no Flutter dependency, so it runs anywhere the Dart VM does: Shelf, Dart Frog, Serverpod, Cloud Functions, CLIs.

The in-app checkout screen is in the Flutter package [`yalla_pay_sudan`](https://pub.dev/packages/yalla_pay_sudan).

> [!WARNING]
> **Server only.** The auth token (`sk_...` / `test_sk_...`) and the webhook secret are secrets. Anyone who has them can create payment links in your name, read your payments' status and forge "payment successful" webhooks. Keep them in your server's environment or secret store. Never put them in a mobile or web app, where anyone can extract them from an APK, IPA or JavaScript bundle.

## How the pieces fit

```
Flutter app ──(1) start checkout──▶ your backend ──(2) createPayment──▶ YallaPaySudan
     ▲                                   │  ◀──────── paymentUrl ─────────┘
     └──────(3) paymentUrl──────────────┘
(4) app opens paymentUrl with YallaPayCheckoutWebView
(5) YallaPaySudan ──webhook──▶ your backend (verifyWebhookBytes) ──▶ marks the order paid
(6) app asks your backend for the order status
```

The app never sees a secret, and the order is only marked paid on the server, based on the verified webhook or `getPaymentStatus`. The redirect the app sees is never treated as proof of payment.

## Install

```bash
dart pub add yalla_pay_sudan_core
```

## Create the client

```dart
final client = YallaPayClient(
  YallaPayConfig.sandbox(
    apiKey: Platform.environment['YALLAPAY_API_KEY']!,
    webhookSecret: Platform.environment['YALLAPAY_WEBHOOK_SECRET'],
  ),
);
```

Use `YallaPayConfig.live(...)` with your `sk_...` token in production. The default timeouts are 30 seconds each. Logging is off by default; when you turn it on (`enableLogging: true`), it never logs headers, so the token stays out of the logs. It does log request and error bodies, so use it in development only.

## Create a payment link

```dart
final response = await client.createPayment(
  PaymentRequest(
    amount: 5000, // SDG, at least PaymentRequest.minimumAmount
    clientReferenceId: orderId, // unique per payment
    description: 'Order $orderId',
    paymentSuccessfulRedirectUrl: 'https://shop.example/payment/success',
    paymentFailedRedirectUrl: 'https://shop.example/payment/failed',
  ),
);

// Send these to the app; nothing else.
final forApp = {
  'paymentUrl': response.paymentUrl,
  'successUrl': response.successRedirectUrl,
  'failedUrl': response.failedRedirectUrl,
};
```

`clientReferenceId` is the gateway's idempotency key: each reference can be used for one payment only.

## Subscriptions

```dart
final response = await client.createSubscription(
  SubscriptionRequest(
    amount: 3000,
    clientReferenceId: subscriptionId,
    description: 'Monthly plan',
    subscriptionConfiguration: const SubscriptionConfiguration(
      interval: SubscriptionInterval.month,
      intervalCycle: 1, // every month
      totalCycles: 12, // omit for no end date
    ),
  ),
);
```

## Check a payment's status

```dart
final status = await client.getPaymentStatus(
  clientReferenceId: orderId,
  transactionDate: DateTime(2026, 4, 2), // the day the payment was created
);

switch (status.status) {
  case PaymentStatus.successful:
    print('Paid ${status.amount} SDG, ref ${status.paymentReferenceId}');
  case PaymentStatus.failed ||
      PaymentStatus.cancelled ||
      PaymentStatus.revoked ||
      PaymentStatus.expired:
    print('Not paid: ${status.status.name}');
  case PaymentStatus.unknown:
    print('New gateway status ${status.rawStatus}; check again later');
}
```

Status checks are read-only, so network errors are retried (`statusRetries`, 2 by default, with backoff).

## Verify webhooks

YallaPaySudan signs `"<timestamp>.<raw body>"` with HMAC-SHA256 and your webhook secret, and sends the result in the `YallaPay-Signature` and `YallaPay-TimeStamp` headers. Verify the **exact bytes you received**, before any JSON parsing:

```dart
Future<int> handleWebhook(
  Map<String, String> headers,
  List<int> rawBody,
) async {
  try {
    final payload = client.verifyWebhookBytes(
      signature: headers['yallapay-signature'] ?? '',
      timestamp: headers['yallapay-timestamp'] ?? '',
      body: rawBody,
    );
    if (await alreadyProcessed(payload.paymentReferenceId, payload.status)) {
      return 200; // a repeated delivery
    }
    switch (payload.status) {
      case PaymentStatus.successful:
        await markOrderPaid(payload.clientReferenceId);
      case PaymentStatus.failed ||
          PaymentStatus.cancelled ||
          PaymentStatus.revoked ||
          PaymentStatus.expired:
        await markOrderUnpaid(payload.clientReferenceId, payload.status);
      case PaymentStatus.unknown:
        await flagForReview(payload.clientReferenceId, payload.rawStatus);
    }
    return 200;
  } on InvalidSignatureException {
    return 401; // forged, altered or stale: ignore it
  } on InvalidResponseException {
    return 400; // correctly signed but not a valid payload
  }
}
```

- The signature is compared in constant time.
- The timestamp must be within `webhookTimestampTolerance` of now (5 minutes by default, in either direction). That limits how long a captured webhook can be replayed. It can't stop a repeat inside the window, and the gateway may legitimately deliver a webhook more than once, so make your handler idempotent, as above.
- Use `verifyWebhook(rawBody: ...)` if your framework only gives you the body as an undecoded string.

## Errors

Every error is a subtype of the sealed `YallaPayException`. Invalid arguments throw `ArgumentError`, before anything is sent.

```dart
try {
  await client.createPayment(request);
} on YallaPayException catch (e) {
  switch (e) {
    case DuplicateReferenceException():
      // Already used: an earlier attempt may have succeeded. Look it up.
      break;
    case PaymentException(:final responseCode):
      print('Rejected by the gateway ($responseCode): ${e.message}');
    case NetworkException(isTimeout: true):
      // It may have reached the gateway: check getPaymentStatus before
      // creating a new reference for the same order.
      break;
    case NetworkException():
      print('Could not reach the gateway: ${e.message}');
    case InvalidResponseException():
      print('Unreadable gateway response: ${e.message}');
    case InvalidSignatureException():
      break; // only thrown by webhook verification
  }
}
```

| Exception | When |
| --- | --- |
| `PaymentException` | The gateway rejected the request (`responseCode`, and `statusCode` for HTTP errors). |
| `DuplicateReferenceException` | A `PaymentException` for a `clientReferenceId` that was already used. |
| `NetworkException` | No connection, DNS or TLS failure, or a timeout (`isTimeout`). |
| `InvalidResponseException` | A response or signed webhook that isn't valid JSON or lacks required fields. |
| `InvalidSignatureException` | A webhook whose signature or timestamp check fails. |

Payment creation is never retried automatically: after a timeout the payment may already exist. Check it with `getPaymentStatus` using the same reference.

## Example

[`example/yalla_pay_sudan_core_example.dart`](example/yalla_pay_sudan_core_example.dart) is a runnable `dart:io` server with a `/checkout` endpoint and a webhook endpoint.

## License

MIT
