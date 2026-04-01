import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../models/payment_response.dart';
import 'checkout_result.dart';

/// A WebView widget for in-app YallaPaySudan checkout.
///
/// Loads the payment URL and intercepts redirects to detect
/// payment success or failure.
///
/// ```dart
/// YallaPayCheckoutWebView(
///   paymentUrl: response.paymentUrl,
///   successUrlPattern: 'https://myapp.com/payment/success',
///   failedUrlPattern: 'https://myapp.com/payment/failed',
///   onCheckoutResult: (result) {
///     Navigator.of(context).pop(result);
///   },
/// )
/// ```
class YallaPayCheckoutWebView extends StatefulWidget {
  /// The payment URL from [PaymentResponse.paymentUrl].
  final String paymentUrl;

  /// URL pattern that indicates a successful payment.
  /// When the WebView navigates to a URL containing this string,
  /// the checkout is considered successful.
  final String? successUrlPattern;

  /// URL pattern that indicates a failed payment.
  final String? failedUrlPattern;

  /// Called when checkout completes with success, failure, or cancellation.
  final ValueChanged<CheckoutResult> onCheckoutResult;

  /// Title displayed in the app bar when using [show].
  final String title;

  /// Whether to show a loading indicator while the page loads.
  final bool showLoadingIndicator;

  /// Custom loading widget to display while the page loads.
  final Widget? loadingWidget;

  /// Custom error widget builder.
  final Widget Function(String error)? errorWidgetBuilder;

  const YallaPayCheckoutWebView({
    super.key,
    required this.paymentUrl,
    required this.onCheckoutResult,
    this.successUrlPattern,
    this.failedUrlPattern,
    this.title = 'YallaPay Checkout',
    this.showLoadingIndicator = true,
    this.loadingWidget,
    this.errorWidgetBuilder,
  });

  /// Shows the checkout WebView as a full-screen modal and returns
  /// the [CheckoutResult] when complete.
  ///
  /// Pass [response] to auto-detect the payment URL and redirect patterns.
  /// Or pass [paymentUrl] + [successUrlPattern] + [failedUrlPattern] manually.
  ///
  /// Returns `null` if the user dismisses without completing checkout.
  static Future<CheckoutResult?> show(
    BuildContext context, {
    PaymentResponse? response,
    String? paymentUrl,
    String? successUrlPattern,
    String? failedUrlPattern,
    String title = 'YallaPay Checkout',
  }) {
    final url = paymentUrl ?? response?.paymentUrl;
    assert(url != null, 'Provide either response or paymentUrl');

    return Navigator.of(context).push<CheckoutResult>(
      MaterialPageRoute(
        builder: (_) => _CheckoutPage(
          paymentUrl: url!,
          successUrlPattern:
              successUrlPattern ?? response?.successRedirectUrl,
          failedUrlPattern:
              failedUrlPattern ?? response?.failedRedirectUrl,
          title: title,
        ),
      ),
    );
  }

  @override
  State<YallaPayCheckoutWebView> createState() =>
      _YallaPayCheckoutWebViewState();
}

class _YallaPayCheckoutWebViewState extends State<YallaPayCheckoutWebView> {
  late final WebViewController _controller;
  bool _isLoading = true;
  String? _error;
  bool _resultFired = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: _handleNavigation,
          onPageFinished: (_) {
            if (mounted) setState(() => _isLoading = false);
          },
          onWebResourceError: (error) {
            if (mounted) {
              setState(() {
                _error = error.description;
                _isLoading = false;
              });
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  NavigationDecision _handleNavigation(NavigationRequest request) {
    final url = request.url;

    if (widget.successUrlPattern != null &&
        url.contains(widget.successUrlPattern!)) {
      _fireResult(CheckoutResult(
        status: CheckoutStatus.success,
        redirectUrl: url,
      ));
      return NavigationDecision.prevent;
    }

    if (widget.failedUrlPattern != null &&
        url.contains(widget.failedUrlPattern!)) {
      _fireResult(CheckoutResult(
        status: CheckoutStatus.failed,
        redirectUrl: url,
      ));
      return NavigationDecision.prevent;
    }

    return NavigationDecision.navigate;
  }

  void _fireResult(CheckoutResult result) {
    if (!_resultFired) {
      _resultFired = true;
      widget.onCheckoutResult(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null && widget.errorWidgetBuilder != null) {
      return widget.errorWidgetBuilder!(_error!);
    }

    return Stack(
      children: [
        WebViewWidget(controller: _controller),
        if (_isLoading && widget.showLoadingIndicator)
          widget.loadingWidget ??
              const Center(child: CircularProgressIndicator()),
      ],
    );
  }
}

/// Internal full-screen page used by [YallaPayCheckoutWebView.show].
class _CheckoutPage extends StatelessWidget {
  final String paymentUrl;
  final String? successUrlPattern;
  final String? failedUrlPattern;
  final String title;

  const _CheckoutPage({
    required this.paymentUrl,
    this.successUrlPattern,
    this.failedUrlPattern,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          Navigator.of(context).pop(
            const CheckoutResult(status: CheckoutStatus.cancelled),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(title),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(
              const CheckoutResult(status: CheckoutStatus.cancelled),
            ),
          ),
        ),
        body: YallaPayCheckoutWebView(
          paymentUrl: paymentUrl,
          successUrlPattern: successUrlPattern,
          failedUrlPattern: failedUrlPattern,
          onCheckoutResult: (result) => Navigator.of(context).pop(result),
        ),
      ),
    );
  }
}
