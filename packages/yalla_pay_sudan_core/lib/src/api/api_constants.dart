/// Base URLs and endpoint paths of the YallaPaySudan gateway API.
abstract final class ApiConstants {
  /// Production API base URL.
  static const String defaultBaseUrl =
      'https://gateway.yallapaysudan.com/api/v1';

  /// Sandbox (test) API base URL.
  static const String sandboxBaseUrl =
      'https://gateway-dev.yallapaysudan.com/api/v1';

  /// The gateway's registrable domain. Checkout pages are served from this
  /// domain or its subdomains.
  static const String gatewayDomain = 'yallapaysudan.com';

  /// Path for creating a one-time payment link.
  static const String generatePaymentLink = '/gateway/generatePaymentLink';

  /// Path for creating a subscription payment link.
  static const String generateSubscriptionPaymentLink =
      '/gateway/generateSubscriptionPaymentLink';

  /// Path for checking the status of a payment.
  static const String getPaymentStatus = '/gateway/getPaymentStatus';
}
