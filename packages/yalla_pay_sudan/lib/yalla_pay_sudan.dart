/// Flutter checkout for the YallaPaySudan payment gateway.
///
/// Opens a YallaPaySudan payment link inside your app with
/// [YallaPayCheckoutWebView] and returns a [CheckoutResult].
///
/// This package deliberately contains no API client: the merchant API key and
/// webhook secret must stay on your server. Create payment links there with the
/// pure Dart `yalla_pay_sudan_core` package and send only the checkout URL to
/// the app.
library;

export 'package:yalla_pay_sudan_core/yalla_pay_sudan_core.dart'
    show PaymentResponse, PaymentStatus;

export 'src/models/checkout_result.dart';
export 'src/widgets/yalla_pay_checkout_webview.dart';
