# yalla_pay_sudan_core

Pure Dart client for the [YallaPaySudan](https://yallapaysudan.com) payment gateway, for **servers**: create one-time payment and subscription links, check payment status and verify webhook signatures. No Flutter dependency, so it runs on the Dart VM (Shelf, Dart Frog, Serverpod, Cloud Functions, CLIs).

For the in-app checkout screen, use the Flutter package [`yalla_pay_sudan`](https://pub.dev/packages/yalla_pay_sudan).

> **Server only.** The auth token (`sk_...` / `test_sk_...`) and the webhook secret are secrets. Keep them on your server and never put them in a mobile or web app.

## Install

```bash
dart pub add yalla_pay_sudan_core
```

## Create a payment link

```dart
import 'package:yalla_pay_sudan_core/yalla_pay_sudan_core.dart';

final client = YallaPayClient(
  YallaPayConfig.sandbox(apiKey: Platform.environment['YALLAPAY_API_KEY']!),
);

final response = await client.createPayment(
  PaymentRequest(
    amount: 5000,
    clientReferenceId: 'order-123',
    paymentSuccessfulRedirectUrl: 'https://example.com/payment/success',
    paymentFailedRedirectUrl: 'https://example.com/payment/failed',
  ),
);
// Send response.paymentUrl to your app.
```

## Verify a webhook

```dart
final payload = client.verifyWebhook(
  signature: request.headers['YallaPay-Signature']!,
  timestamp: request.headers['YallaPay-TimeStamp']!,
  rawBody: rawBody,
);
```

See [`example/yalla_pay_sudan_core_example.dart`](example/yalla_pay_sudan_core_example.dart) for a runnable server.

## License

MIT
