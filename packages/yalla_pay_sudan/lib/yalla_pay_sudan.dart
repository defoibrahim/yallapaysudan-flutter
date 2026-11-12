/// Flutter checkout for the YallaPaySudan payment gateway.
///
/// Opens a payment link from your backend inside the app with
/// [YallaPayCheckoutWebView] and reports how the checkout ended as a
/// [CheckoutResult].
///
/// This package deliberately has no API client. Creating payment links needs
/// the merchant auth token, which must stay on your server: create them there
/// with the pure Dart `yalla_pay_sudan_core` package and send only the
/// checkout URL and redirect URLs to the app.
library;

export 'package:yalla_pay_sudan_core/yalla_pay_sudan_core.dart'
    show PaymentResponse, PaymentStatus;

export 'src/models/checkout_result.dart';
export 'src/widgets/yalla_pay_checkout_webview.dart';
