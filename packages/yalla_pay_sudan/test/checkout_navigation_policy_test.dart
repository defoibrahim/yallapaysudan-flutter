import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_pay_sudan/src/navigation/checkout_navigation_policy.dart';

void main() {
  final policy = CheckoutNavigationPolicy(
    successUrl: 'https://shop.example/pay/ok',
    failedUrl: 'https://shop.example:8443/pay/fail/',
  );

  CheckoutNavigationAction decide(String url, {bool isMainFrame = true}) =>
      policy.decide(url, isMainFrame: isMainFrame);

  test('exact redirect matches, ignoring query, fragment and trailing slash', () {
    expect(decide('https://shop.example/pay/ok'), CheckoutNavigationAction.success);
    expect(decide('https://SHOP.example/pay/ok/?a=1#b'), CheckoutNavigationAction.success);
    expect(decide('https://shop.example:8443/pay/fail'), CheckoutNavigationAction.failure);
  });

  test('scheme, port and path must match', () {
    expect(decide('http://shop.example/pay/ok'), CheckoutNavigationAction.block);
    expect(decide('https://shop.example:444/pay/ok'), CheckoutNavigationAction.block);
    expect(decide('https://shop.example/pay/fail'), CheckoutNavigationAction.block);
    expect(decide('https://shop.example/pay/ok/extra'), CheckoutNavigationAction.block);
    expect(decide('https://shop.example/PAY/ok'), CheckoutNavigationAction.block);
  });

  test('unparseable URLs are blocked', () {
    expect(decide('https://exa mple.com:99999/'), CheckoutNavigationAction.block);
  });

  test('allowed hosts include subdomains only on a dot boundary', () {
    expect(policy.isAllowedHost('yallapaysudan.com'), isTrue);
    expect(policy.isAllowedHost('gateway.yallapaysudan.com'), isTrue);
    expect(policy.isAllowedHost('evilyallapaysudan.com'), isFalse);
    expect(policy.isAllowedHost('yallapaysudan.com.evil.example'), isFalse);
  });

  test('redirect URLs must be absolute http(s) URLs', () {
    for (final bad in ['/ok', 'myapp://ok', 'ok']) {
      expect(
        () => CheckoutNavigationPolicy(successUrl: bad, failedUrl: 'https://a.example/f'),
        throwsFormatException,
        reason: bad,
      );
    }
  });
}
