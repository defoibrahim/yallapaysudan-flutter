abstract final class ApiConstants {
  /// Production base URL.
  static const String defaultBaseUrl =
      'https://gateway.yallapaysudan.com/api/v1';

  /// Sandbox base URL for testing.
  static const String sandboxBaseUrl =
      'https://gateway-dev.yallapaysudan.com/api/v1';

  static const String generatePaymentLink = '/gateway/generatePaymentLink';

  static const String generateSubscriptionPaymentLink =
      '/gateway/generateSubscriptionPaymentLink';
}
