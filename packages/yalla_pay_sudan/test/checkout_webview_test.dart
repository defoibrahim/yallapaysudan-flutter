import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';
import 'package:yalla_pay_sudan/yalla_pay_sudan.dart';

import 'support/fake_webview_platform.dart';

const paymentUrl = 'https://gateway.yallapaysudan.com/checkout/web/abc';
const successUrl = 'https://shop.example/payment/success';
const failedUrl = 'https://shop.example/payment/failed';

void main() {
  late FakeWebViewPlatform platform;
  late List<CheckoutResult> results;
  late List<Uri> blocked;

  setUp(() {
    platform = FakeWebViewPlatform();
    WebViewPlatform.instance = platform;
    results = [];
    blocked = [];
  });

  Future<void> pumpCheckout(
    WidgetTester tester, {
    String url = paymentUrl,
    String success = successUrl,
    String failed = failedUrl,
    List<String> allowedHosts = YallaPayCheckoutWebView.defaultAllowedHosts,
    CheckoutErrorBuilder? errorBuilder,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: YallaPayCheckoutWebView(
            paymentUrl: url,
            successUrl: success,
            failedUrl: failed,
            allowedHosts: allowedHosts,
            onCheckoutResult: results.add,
            onNavigationBlocked: blocked.add,
            errorBuilder: errorBuilder,
          ),
        ),
      ),
    );
  }

  group('loading', () {
    testWidgets('loads the payment URL with JavaScript enabled', (
      tester,
    ) async {
      await pumpCheckout(tester);

      expect(platform.controller.loadedUris, [Uri.parse(paymentUrl)]);
      expect(platform.controller.javaScriptMode, JavaScriptMode.unrestricted);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      platform.delegate.onPageFinished!(paymentUrl);
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('refuses a payment URL outside the allowed hosts', (
      tester,
    ) async {
      await pumpCheckout(tester, url: 'https://evil.example/checkout');

      expect(platform.controller.loadedUris, isEmpty);
      expect(find.textContaining('not a YallaPaySudan'), findsOneWidget);
    });

    testWidgets('refuses a non-https payment URL', (tester) async {
      await pumpCheckout(
        tester,
        url: 'http://gateway.yallapaysudan.com/checkout/web/abc',
      );

      expect(platform.controller.loadedUris, isEmpty);
    });

    testWidgets('shows an error for an invalid redirect URL', (tester) async {
      await pumpCheckout(tester, success: '/relative/path');

      expect(platform.controller.loadedUris, isEmpty);
      expect(find.textContaining('Invalid redirect URL'), findsOneWidget);
    });
  });

  group('redirect detection', () {
    testWidgets('success URL reports success once and is not loaded', (
      tester,
    ) async {
      await pumpCheckout(tester);

      final decision = await platform.delegate.navigate(
        '$successUrl?ref=yp-123#done',
      );
      await platform.delegate.navigate(successUrl);

      expect(decision, NavigationDecision.prevent);
      expect(results, [
        const CheckoutResult(
          status: PaymentStatus.successful,
          redirectUrl: '$successUrl?ref=yp-123#done',
        ),
      ]);
    });

    testWidgets('failure URL reports failure', (tester) async {
      await pumpCheckout(tester);

      final decision = await platform.delegate.navigate('$failedUrl/');

      expect(decision, NavigationDecision.prevent);
      expect(results.single.status, PaymentStatus.failed);
    });

    testWidgets('a success URL inside another URL does not match', (
      tester,
    ) async {
      await pumpCheckout(tester);

      final spoof = 'https://evil.example/?next=$successUrl';
      final decision = await platform.delegate.navigate(spoof);

      expect(decision, NavigationDecision.prevent);
      expect(results, isEmpty);
      expect(blocked, [Uri.parse(spoof)]);
    });

    testWidgets('a longer path on the same host does not match', (
      tester,
    ) async {
      await pumpCheckout(
        tester,
        allowedHosts: ['yallapaysudan.com', 'shop.example'],
      );

      final decision = await platform.delegate.navigate('$successUrl-page');

      expect(decision, NavigationDecision.navigate);
      expect(results, isEmpty);
    });

    testWidgets('a lookalike host does not match', (tester) async {
      await pumpCheckout(tester);

      await platform.delegate.navigate(
        'https://shop.example.evil.example/payment/success',
      );

      expect(results, isEmpty);
    });

    testWidgets('redirects seen in onPageStarted are detected', (tester) async {
      await pumpCheckout(tester);

      platform.delegate.onPageStarted!(failedUrl);

      expect(results.single.status, PaymentStatus.failed);
    });

    testWidgets('redirects seen in onUrlChange are detected', (tester) async {
      await pumpCheckout(tester);

      platform.delegate.onUrlChange!(const UrlChange(url: '$successUrl?x=1'));

      expect(results.single.status, PaymentStatus.successful);
    });

    testWidgets('frames never trigger a result', (tester) async {
      await pumpCheckout(tester);

      final decision = await platform.delegate.navigate(
        successUrl,
        isMainFrame: false,
      );

      expect(decision, NavigationDecision.navigate);
      expect(results, isEmpty);
    });
  });

  group('navigation allow-list', () {
    testWidgets('gateway pages and subdomains load', (tester) async {
      await pumpCheckout(tester);

      for (final url in [
        'https://gateway.yallapaysudan.com/checkout/web/abc/step2',
        'https://pay.gateway-dev.yallapaysudan.com/x',
        'https://YALLAPAYSUDAN.com/',
      ]) {
        expect(
          await platform.delegate.navigate(url),
          NavigationDecision.navigate,
          reason: url,
        );
      }
      expect(blocked, isEmpty);
    });

    testWidgets('other hosts, http and app schemes are blocked', (
      tester,
    ) async {
      await pumpCheckout(tester);

      const urls = [
        'https://phishing.example/checkout',
        'https://notyallapaysudan.com/',
        'http://gateway.yallapaysudan.com/checkout',
        'intent://pay#Intent;scheme=bravo;end',
        'tel:+249123456789',
        'javascript:alert(1)',
        'data:text/html,Paid',
      ];
      for (final url in urls) {
        expect(
          await platform.delegate.navigate(url),
          NavigationDecision.prevent,
          reason: url,
        );
      }
      expect(blocked, [for (final url in urls) Uri.parse(url)]);
      expect(results, isEmpty);
    });

    testWidgets('extra allowed hosts load', (tester) async {
      await pumpCheckout(
        tester,
        allowedHosts: ['yallapaysudan.com', 'bank.example'],
      );

      expect(
        await platform.delegate.navigate('https://secure.bank.example/3ds'),
        NavigationDecision.navigate,
      );
    });

    testWidgets('https frames from other hosts may load', (tester) async {
      await pumpCheckout(tester);

      expect(
        await platform.delegate.navigate(
          'https://www.google.com/recaptcha/api2/anchor',
          isMainFrame: false,
        ),
        NavigationDecision.navigate,
      );
      expect(
        await platform.delegate.navigate('about:blank', isMainFrame: false),
        NavigationDecision.navigate,
      );
      expect(
        await platform.delegate.navigate(
          'http://tracker.example/pixel',
          isMainFrame: false,
        ),
        NavigationDecision.prevent,
      );
    });
  });

  group('errors', () {
    testWidgets('sub-resource errors are ignored', (tester) async {
      await pumpCheckout(tester);

      platform.delegate.onWebResourceError!(
        const WebResourceError(
          errorCode: -2,
          description: 'favicon failed',
          isForMainFrame: false,
        ),
      );
      await tester.pump();

      expect(find.text('favicon failed'), findsNothing);
      expect(find.byKey(const ValueKey('fake-webview')), findsOneWidget);
    });

    testWidgets('main-frame errors show a retry that reloads', (tester) async {
      await pumpCheckout(tester);

      platform.delegate.onWebResourceError!(
        const WebResourceError(
          errorCode: -2,
          description: 'net::ERR_NAME_NOT_RESOLVED',
          isForMainFrame: true,
        ),
      );
      await tester.pump();

      expect(find.text('net::ERR_NAME_NOT_RESOLVED'), findsOneWidget);

      await tester.tap(find.text('Try again'));
      await tester.pump();

      expect(platform.controller.loadedUris, hasLength(2));
      expect(find.byKey(const ValueKey('fake-webview')), findsOneWidget);
    });

    testWidgets('custom error builder', (tester) async {
      await pumpCheckout(
        tester,
        errorBuilder: (context, message, retry) => Text('Oops: $message'),
      );

      platform.delegate.onWebResourceError!(
        const WebResourceError(errorCode: -6, description: 'offline'),
      );
      await tester.pump();

      expect(find.text('Oops: offline'), findsOneWidget);
    });
  });

  group('show', () {
    Future<Future<CheckoutResult>> open(
      WidgetTester tester, {
      PaymentResponse? response,
      String? url = paymentUrl,
      String? success = successUrl,
      String? failed = failedUrl,
    }) async {
      late Future<CheckoutResult> result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () {
                result = YallaPayCheckoutWebView.show(
                  context,
                  response: response,
                  paymentUrl: url,
                  successUrl: success,
                  failedUrl: failed,
                );
                // Errors are asserted later; don't report them as uncaught.
                result.ignore();
              },
              child: const Text('Pay'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Pay'));
      // Let the route transition finish. (pumpAndSettle would wait forever:
      // the loading spinner keeps animating because the fake page never
      // finishes loading.)
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      return result;
    }

    testWidgets('returns the result and closes the page', (tester) async {
      final result = await open(tester);

      await platform.delegate.navigate(successUrl);
      await tester.pumpAndSettle();

      expect((await result).status, PaymentStatus.successful);
      expect(find.text('Pay'), findsOneWidget);
    });

    testWidgets('the close button returns cancelled', (tester) async {
      final result = await open(tester);

      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();

      expect((await result).status, PaymentStatus.cancelled);
    });

    testWidgets('system back returns cancelled', (tester) async {
      final result = await open(tester);

      // What the system back gesture does: ask the top route to pop.
      tester.state<NavigatorState>(find.byType(Navigator)).maybePop();
      await tester.pumpAndSettle();

      expect((await result).isCancelled, isTrue);
    });

    testWidgets('reads the URLs from a PaymentResponse', (tester) async {
      final result = await open(
        tester,
        url: null,
        success: null,
        failed: null,
        response: const PaymentResponse(
          responseCode: '0',
          responseMessage: 'Success',
          currentDate: '',
          currentTime: '',
          paymentUrl: paymentUrl,
          raw: {},
          successRedirectUrl: successUrl,
          failedRedirectUrl: failedUrl,
        ),
      );

      expect(platform.controller.loadedUris, [Uri.parse(paymentUrl)]);
      await platform.delegate.navigate(failedUrl);
      await tester.pumpAndSettle();

      expect((await result).isFailed, isTrue);
    });

    testWidgets('throws without redirect URLs', (tester) async {
      final result = await open(tester, success: null);

      await expectLater(result, throwsArgumentError);
      expect(platform.controllers, isEmpty);
    });

    testWidgets('throws without a payment URL', (tester) async {
      final result = await open(tester, url: null);

      await expectLater(result, throwsArgumentError);
    });
  });
}
