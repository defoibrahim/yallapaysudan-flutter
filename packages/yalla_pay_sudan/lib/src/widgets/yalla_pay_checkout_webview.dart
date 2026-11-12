import 'package:material_ui/material_ui.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:yalla_pay_sudan_core/yalla_pay_sudan_core.dart'
    show ApiConstants, PaymentResponse, PaymentStatus;

import '../models/checkout_result.dart';
import '../navigation/checkout_navigation_policy.dart';

/// Builds the view shown when the checkout page cannot be loaded. Call
/// [retry] to load the payment URL again.
typedef CheckoutErrorBuilder =
    Widget Function(BuildContext context, String message, VoidCallback retry);

/// An in-app YallaPaySudan checkout.
///
/// Loads [paymentUrl] (created by **your backend** with
/// `yalla_pay_sudan_core`) and reports how the checkout ended through
/// [onCheckoutResult]:
///
/// * navigating to [successUrl] reports [PaymentStatus.successful];
/// * navigating to [failedUrl] reports [PaymentStatus.failed].
///
/// The redirect URLs match on scheme, host, port and path; query and
/// fragment are ignored. Top-level pages may only be `https` pages on
/// [allowedHosts] (by default the gateway's domain); everything else is
/// blocked and passed to [onNavigationBlocked].
///
/// **The result is a UI hint, not proof of payment.** Anything that can run
/// in the page could navigate to the success URL. Mark orders paid on your
/// server, from the verified webhook or a status check, and have the app ask
/// your server for the order status.
///
/// Most apps use [YallaPayCheckoutWebView.show], which opens a full-screen
/// page with a close button and returns the result.
class YallaPayCheckoutWebView extends StatefulWidget {
  /// The default [allowedHosts]: the gateway's domain and its subdomains.
  static const List<String> defaultAllowedHosts = [ApiConstants.gatewayDomain];

  /// The checkout URL from your backend ([PaymentResponse.paymentUrl]). Must
  /// be `https` on one of [allowedHosts].
  final String paymentUrl;

  /// The `paymentSuccessfulRedirectUrl` the payment was created with.
  final String successUrl;

  /// The `paymentFailedRedirectUrl` the payment was created with.
  final String failedUrl;

  /// Called once, when the checkout reaches [successUrl] or [failedUrl].
  final ValueChanged<CheckoutResult> onCheckoutResult;

  /// Hosts that top-level pages may be on, including their subdomains.
  ///
  /// Add a host only if the payment flow needs it (for example a bank page
  /// the gateway redirects to) and you trust it.
  final List<String> allowedHosts;

  /// Called with each navigation that was blocked: a top-level page outside
  /// [allowedHosts], plain `http`, or another scheme such as `intent:`,
  /// `tel:` or a banking app link. Use it to hand app links to the system,
  /// for example with `url_launcher`, or to log unexpected navigations.
  final ValueChanged<Uri>? onNavigationBlocked;

  /// Whether to show a progress indicator until the first page has loaded.
  final bool showLoadingIndicator;

  /// Replaces the default progress indicator.
  final Widget? loadingWidget;

  /// Replaces the default error view (a message with a "Try again" button).
  final CheckoutErrorBuilder? errorBuilder;

  /// Creates a checkout view. [successUrl] and [failedUrl] are required:
  /// without them the end of the checkout cannot be detected.
  const YallaPayCheckoutWebView({
    super.key,
    required this.paymentUrl,
    required this.successUrl,
    required this.failedUrl,
    required this.onCheckoutResult,
    this.allowedHosts = defaultAllowedHosts,
    this.onNavigationBlocked,
    this.showLoadingIndicator = true,
    this.loadingWidget,
    this.errorBuilder,
  });

  /// Opens the checkout full screen and completes with the result.
  ///
  /// Pass the [response] your backend created, or [paymentUrl], [successUrl]
  /// and [failedUrl] directly; explicit values win over [response].
  ///
  /// Completes with [PaymentStatus.cancelled] when the customer closes the
  /// page (close button or system back). A cancelled checkout does not prove
  /// that nothing was paid: ask your backend.
  ///
  /// Throws [ArgumentError] if no payment URL or redirect URL is available.
  static Future<CheckoutResult> show(
    BuildContext context, {
    PaymentResponse? response,
    String? paymentUrl,
    String? successUrl,
    String? failedUrl,
    String title = 'YallaPay Checkout',
    List<String> allowedHosts = defaultAllowedHosts,
    ValueChanged<Uri>? onNavigationBlocked,
  }) async {
    final url = paymentUrl ?? response?.paymentUrl;
    final success = successUrl ?? response?.successRedirectUrl;
    final failed = failedUrl ?? response?.failedRedirectUrl;
    if (url == null || url.isEmpty) {
      throw ArgumentError('Pass a response or a paymentUrl.');
    }
    if (success == null || failed == null) {
      throw ArgumentError(
        'Both redirect URLs are required to detect the end of the checkout. '
        'Create the payment with paymentSuccessfulRedirectUrl and '
        'paymentFailedRedirectUrl, or pass successUrl and failedUrl.',
      );
    }
    final result = await Navigator.of(context).push<CheckoutResult>(
      MaterialPageRoute(
        builder: (_) => _CheckoutPage(
          title: title,
          checkout: (onResult) => YallaPayCheckoutWebView(
            paymentUrl: url,
            successUrl: success,
            failedUrl: failed,
            allowedHosts: allowedHosts,
            onNavigationBlocked: onNavigationBlocked,
            onCheckoutResult: onResult,
          ),
        ),
      ),
    );
    return result ?? const CheckoutResult(status: PaymentStatus.cancelled);
  }

  @override
  State<YallaPayCheckoutWebView> createState() =>
      _YallaPayCheckoutWebViewState();
}

class _YallaPayCheckoutWebViewState extends State<YallaPayCheckoutWebView> {
  late final WebViewController _controller;
  CheckoutNavigationPolicy? _policy;
  bool _isLoading = true;
  String? _error;
  bool _resultFired = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      // The hosted checkout page needs JavaScript. No JavaScript channels are
      // added, so the page cannot call into the app.
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: _onNavigationRequest,
          // Some redirects (for example after a form POST on Android) and
          // in-page URL changes skip onNavigationRequest, so the end of the
          // checkout is also detected here.
          onPageStarted: _onUrlSeen,
          onUrlChange: (change) {
            final url = change.url;
            if (url != null) _onUrlSeen(url);
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _isLoading = false);
          },
          onWebResourceError: _onWebResourceError,
        ),
      );
    try {
      _policy = CheckoutNavigationPolicy(
        successUrl: widget.successUrl,
        failedUrl: widget.failedUrl,
        allowedHosts: widget.allowedHosts,
      );
    } on FormatException catch (e) {
      _error = 'Invalid redirect URL: ${e.message}.';
      _isLoading = false;
      return;
    }
    _load();
  }

  void _load() {
    final policy = _policy;
    final uri = Uri.tryParse(widget.paymentUrl);
    if (policy == null ||
        uri == null ||
        !uri.isScheme('https') ||
        !policy.isAllowedHost(uri.host)) {
      _error = 'This checkout link is not a YallaPaySudan https page.';
      _isLoading = false;
      return;
    }
    _controller.loadRequest(uri);
  }

  void _retry() {
    setState(() {
      _error = null;
      _isLoading = true;
      _load();
    });
  }

  NavigationDecision _onNavigationRequest(NavigationRequest request) {
    final policy = _policy;
    if (policy == null) return NavigationDecision.prevent;
    switch (policy.decide(request.url, isMainFrame: request.isMainFrame)) {
      case CheckoutNavigationAction.success:
        _fireResult(PaymentStatus.successful, request.url);
        return NavigationDecision.prevent;
      case CheckoutNavigationAction.failure:
        _fireResult(PaymentStatus.failed, request.url);
        return NavigationDecision.prevent;
      case CheckoutNavigationAction.load:
        return NavigationDecision.navigate;
      case CheckoutNavigationAction.block:
        final uri = Uri.tryParse(request.url);
        if (uri != null) widget.onNavigationBlocked?.call(uri);
        return NavigationDecision.prevent;
    }
  }

  void _onUrlSeen(String url) {
    switch (_policy?.decide(url)) {
      case CheckoutNavigationAction.success:
        _fireResult(PaymentStatus.successful, url);
      case CheckoutNavigationAction.failure:
        _fireResult(PaymentStatus.failed, url);
      case CheckoutNavigationAction.load ||
          CheckoutNavigationAction.block ||
          null:
        break;
    }
  }

  void _onWebResourceError(WebResourceError error) {
    // Failed images, scripts or frames are not a failed checkout page.
    if (error.isForMainFrame == false || _resultFired || !mounted) return;
    setState(() {
      _error = error.description.isEmpty
          ? 'The checkout page could not be loaded.'
          : error.description;
      _isLoading = false;
    });
  }

  void _fireResult(PaymentStatus status, String url) {
    if (_resultFired) return;
    _resultFired = true;
    widget.onCheckoutResult(CheckoutResult(status: status, redirectUrl: url));
  }

  @override
  Widget build(BuildContext context) {
    final error = _error;
    if (error != null) {
      final builder = widget.errorBuilder;
      if (builder != null) return builder(context, error, _retry);
      return _DefaultError(message: error, onRetry: _retry);
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

class _DefaultError extends StatelessWidget {
  const _DefaultError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}

/// Full-screen page used by [YallaPayCheckoutWebView.show].
class _CheckoutPage extends StatelessWidget {
  const _CheckoutPage({required this.title, required this.checkout});

  final String title;
  final Widget Function(ValueChanged<CheckoutResult> onResult) checkout;

  static const _cancelled = CheckoutResult(status: PaymentStatus.cancelled);

  @override
  Widget build(BuildContext context) {
    return PopScope<CheckoutResult>(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.of(context).pop(_cancelled);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(title),
          leading: IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Close',
            onPressed: () => Navigator.of(context).pop(_cancelled),
          ),
        ),
        body: checkout((result) => Navigator.of(context).pop(result)),
      ),
    );
  }
}
