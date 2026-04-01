# YallaPay Sudan

Flutter SDK for the [YallaPaySudan](https://yallapaysudan.com) payment gateway. Supports one-time payments, recurring subscriptions, webhook signature verification, and in-app WebView checkout.

## Features

- **One-time payments** -- Generate payment links via the YallaPaySudan API
- **Subscriptions** -- Recurring billing with configurable intervals (day/month/year)
- **In-app checkout** -- Built-in WebView widget with redirect detection
- **Webhook verification** -- HMAC-SHA256 signature verification with replay attack protection
- **Type-safe** -- Immutable models, sealed exceptions, and exhaustive error handling

## Getting Started

### 1. Install

```yaml
dependencies:
  yalla_pay_sudan: ^1.0.0
```

```bash
flutter pub get
```

### 2. Get your credentials

Go to the [YallaPaySudan Dashboard](https://dashboard.yallapaysudan.com) > **Developer** tab:

- Copy your **Auth Token** (test or production)
- Set up a **Webhook Secret** under Webhooks
- Note the **Base URL** for your environment

### 3. Choose your environment

| Environment | Base URL                                          | Token prefix |
| ----------- | ------------------------------------------------- | ------------ |
| Sandbox     | `https://gateway-dev.yallapaysudan.com/api/v1`    | `test_sk_*`  |
| Production  | `https://gateway.yallapaysudan.com/api/v1`        | `sk_*`       |

### 4. Create the client

```dart
import 'package:yalla_pay_sudan/yalla_pay_sudan.dart';

final client = YallaPayClient(
  YallaPayConfig(
    apiKey: 'your-auth-token',
    baseUrl: ApiConstants.sandboxBaseUrl,  // or omit for production
  ),
);
```

## Usage

### One-Time Payment

```dart
try {
  final response = await client.createPayment(
    PaymentRequest(
      amount: 5000,                       // SDG, minimum 1,000
      clientReferenceId: 'order-123',     // Must be unique per payment
      description: 'Product purchase',
      paymentSuccessfulRedirectUrl: 'https://myapp.com/success',
      paymentFailedRedirectUrl: 'https://myapp.com/failed',
    ),
  );

  print('Checkout URL: ${response.paymentUrl}');
} on PaymentException catch (e) {
  print('API error: ${e.message} (code: ${e.responseCode})');
} on NetworkException catch (e) {
  print('Network error: ${e.message}');
}
```

> **Note:** `clientReferenceId` must be unique for every payment request. Reusing an ID returns a "Duplicate client reference ID" error.

### Subscription Payment

```dart
final response = await client.createSubscription(
  SubscriptionRequest(
    amount: 3000,
    clientReferenceId: 'sub-456',
    description: 'Monthly plan',
    subscriptionConfiguration: SubscriptionConfiguration(
      interval: SubscriptionInterval.month,
      intervalCycle: 1,       // Every 1 month
      totalCycles: 12,        // 12 months total (omit for indefinite)
    ),
  ),
);
```

### In-App WebView Checkout

Open the checkout page directly inside your app. The redirect URLs are automatically read from the `PaymentResponse`:

```dart
final result = await YallaPayCheckoutWebView.show(
  context,
  response: response,
);

switch (result?.status) {
  case CheckoutStatus.success:
    // Payment completed
  case CheckoutStatus.failed:
    // Payment failed
  case CheckoutStatus.cancelled:
  case null:
    // User dismissed the checkout
}
```

The WebView intercepts navigation to your success/failure redirect URLs and closes automatically. If the user presses back, the result is `CheckoutStatus.cancelled`.

You can also pass URLs manually if needed:

```dart
final result = await YallaPayCheckoutWebView.show(
  context,
  paymentUrl: response.paymentUrl,
  successUrlPattern: 'https://myapp.com/success',
  failedUrlPattern: 'https://myapp.com/failed',
);
```

Or embed the widget directly in your widget tree:

```dart
YallaPayCheckoutWebView(
  paymentUrl: response.paymentUrl,
  successUrlPattern: 'https://myapp.com/success',
  failedUrlPattern: 'https://myapp.com/failed',
  onCheckoutResult: (result) {
    // Handle result
  },
)
```

### Webhook Verification

For Dart backends (Shelf, Dart Frog, Serverpod) -- verify that incoming webhooks are authentic:

```dart
final client = YallaPayClient(
  YallaPayConfig(
    apiKey: 'your-auth-token',
    webhookSecret: 'your-webhook-secret',
  ),
);

try {
  final payload = client.verifyWebhook(
    signature: headers['YallaPay-Signature']!,
    timestamp: headers['YallaPay-TimeStamp']!,
    rawBody: requestBody,
  );

  switch (payload.status) {
    case PaymentStatus.successful:
      await markOrderPaid(payload.clientReferenceId);
    case PaymentStatus.failed:
      await markOrderFailed(payload.clientReferenceId);
    case PaymentStatus.cancelled:
      await markOrderCancelled(payload.clientReferenceId);
  }
} on InvalidSignatureException {
  // Return HTTP 401 -- invalid signature or replay attack
}
```

> **How it works:** YallaPaySudan signs `"$timestamp.$rawBody"` with HMAC-SHA256 using your webhook secret. This package recomputes the signature and compares it using constant-time comparison to prevent timing attacks. Timestamps older than 5 minutes (configurable) are rejected to prevent replay attacks.

## Error Handling

All exceptions extend the sealed `YallaPayException` class for exhaustive matching:

```dart
try {
  final response = await client.createPayment(request);
} on YallaPayException catch (e) {
  switch (e) {
    case PaymentException():
      print('API error: ${e.responseCode} -- ${e.message}');
    case NetworkException():
      print('Network error: ${e.message}');
    case InvalidSignatureException():
      print('Signature error: ${e.message}');
  }
}
```

| Exception                   | When                                              |
| --------------------------- | ------------------------------------------------- |
| `PaymentException`          | API returned an error (with `responseCode`)       |
| `NetworkException`          | Timeout, no connection, DNS failure               |
| `InvalidSignatureException` | Webhook HMAC mismatch or expired timestamp        |
| `ArgumentError`             | Invalid input (amount < 1000, empty reference ID) |

## API Reference

### YallaPayConfig

| Property                    | Type     | Default                                    | Description                          |
| --------------------------- | -------- | ------------------------------------------ | ------------------------------------ |
| `apiKey`                    | String   | **required**                               | Auth token from dashboard            |
| `baseUrl`                   | String   | `gateway.yallapaysudan.com/api/v1`         | API base URL                         |
| `webhookSecret`             | String?  | null                                       | For webhook signature verification   |
| `webhookTimestampTolerance` | Duration | 5 minutes                                  | Max age for webhook timestamps       |
| `connectTimeout`            | Duration | 30 seconds                                 | HTTP connection timeout              |
| `receiveTimeout`            | Duration | 30 seconds                                 | HTTP response timeout                |
| `enableLogging`             | bool     | false                                      | Log requests/responses (debug only)  |

### PaymentResponse

| Property             | Type    | Description                           |
| -------------------- | ------- | ------------------------------------- |
| `responseCode`       | String  | `"0"` = success                       |
| `responseMessage`    | String  | Human-readable message                |
| `paymentUrl`         | String  | Checkout URL for the customer         |
| `isSuccess`          | bool    | Whether responseCode is "0"           |
| `successRedirectUrl` | String? | Auto-filled from your payment request |
| `failedRedirectUrl`  | String? | Auto-filled from your payment request |

### WebhookPayload

| Property              | Type          | Description                    |
| --------------------- | ------------- | ------------------------------ |
| `clientReferenceId`   | String        | Your transaction ID            |
| `paymentReferenceId`  | String        | YallaPaySudan transaction ID   |
| `status`              | PaymentStatus | `successful`/`failed`/`cancelled` |
| `isSuccessful`        | bool          | Convenience getter             |

## Cleanup

Always dispose the client when done:

```dart
client.dispose();
```

## License

MIT
