# yalla_pay_sudan

Flutter checkout for the [YallaPaySudan](https://yallapaysudan.com) payment gateway. Your backend creates a payment link; this package opens it in an in-app WebView and tells you how the checkout ended.

> **Version 2 moves the API client to the server.** Creating payment links needs the merchant auth token (`sk_...`), which must never ship inside an app. Use the pure Dart [`yalla_pay_sudan_core`](https://pub.dev/packages/yalla_pay_sudan_core) package on your backend.

## Screenshots

| Main Screen | Checkout | Payment Success | Result |
| :-: | :-: | :-: | :-: |
| ![Main](https://raw.githubusercontent.com/defoibrahim/yallapaysudan-flutter/main/screenshots/1_main_dark.png) | ![Checkout](https://raw.githubusercontent.com/defoibrahim/yallapaysudan-flutter/main/screenshots/2_checkout.png) | ![Success](https://raw.githubusercontent.com/defoibrahim/yallapaysudan-flutter/main/screenshots/3_payment_succ.png) | ![Result](https://raw.githubusercontent.com/defoibrahim/yallapaysudan-flutter/main/screenshots/4_payment_result.png) |

## Install

```bash
flutter pub add yalla_pay_sudan
```

## In-app checkout

Get the checkout URL from your backend, then:

```dart
final result = await YallaPayCheckoutWebView.show(
  context,
  paymentUrl: paymentUrl,
  successUrl: 'https://example.com/payment/success',
  failedUrl: 'https://example.com/payment/failed',
);
```

## License

MIT
