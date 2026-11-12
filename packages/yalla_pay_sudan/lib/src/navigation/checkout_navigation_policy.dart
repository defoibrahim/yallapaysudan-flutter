import 'package:yalla_pay_sudan_core/yalla_pay_sudan_core.dart'
    show ApiConstants;

/// What the checkout WebView does with a navigation.
enum CheckoutNavigationAction {
  /// The success redirect URL was reached: report success, don't load it.
  success,

  /// The failure redirect URL was reached: report failure, don't load it.
  failure,

  /// An allowed page: let the WebView load it.
  load,

  /// Not allowed: don't load it.
  block,
}

/// Decides where the checkout WebView may go and when checkout has ended.
///
/// * The redirect URLs match on scheme, host, port and path. Query and
///   fragment are ignored, so the gateway may append parameters, but a URL
///   that only *contains* the redirect URL (for example in its query string)
///   does not match.
/// * Top-level (main-frame) pages must be `https` on one of [allowedHosts]
///   or a subdomain of one (by default the gateway's domain).
/// * Embedded frames may load any `https` page (payment widgets, captchas)
///   but never trigger a result.
/// * Every other scheme (`http`, `intent`, `tel`, app links...) is blocked.
class CheckoutNavigationPolicy {
  /// The success redirect URL.
  final Uri successUrl;

  /// The failure redirect URL.
  final Uri failedUrl;

  /// Hosts (and their subdomains) top-level pages may be on, lowercase.
  final Set<String> allowedHosts;

  /// Creates a policy. Throws [FormatException] if a redirect URL is not an
  /// absolute http(s) URL.
  CheckoutNavigationPolicy({
    required String successUrl,
    required String failedUrl,
    Iterable<String> allowedHosts = const [ApiConstants.gatewayDomain],
  }) : successUrl = _parseRedirect(successUrl, 'successUrl'),
       failedUrl = _parseRedirect(failedUrl, 'failedUrl'),
       allowedHosts = {for (final host in allowedHosts) host.toLowerCase()};

  static Uri _parseRedirect(String url, String name) {
    final uri = Uri.parse(url);
    if (!(uri.isScheme('https') || uri.isScheme('http')) || uri.host.isEmpty) {
      throw FormatException('$name must be an absolute http(s) URL', url);
    }
    return uri;
  }

  /// Decides what to do with a navigation to [url].
  CheckoutNavigationAction decide(String url, {bool isMainFrame = true}) {
    final uri = Uri.tryParse(url);
    if (uri == null) return CheckoutNavigationAction.block;
    if (isMainFrame) {
      if (matchesRedirect(uri, successUrl)) {
        return CheckoutNavigationAction.success;
      }
      if (matchesRedirect(uri, failedUrl)) {
        return CheckoutNavigationAction.failure;
      }
    }
    if (!uri.isScheme('https')) {
      // about:blank and srcdoc frames are part of normal pages.
      final isBlankFrame = !isMainFrame && uri.isScheme('about');
      return isBlankFrame
          ? CheckoutNavigationAction.load
          : CheckoutNavigationAction.block;
    }
    if (!isMainFrame || isAllowedHost(uri.host)) {
      return CheckoutNavigationAction.load;
    }
    return CheckoutNavigationAction.block;
  }

  /// Whether [host] is one of [allowedHosts] or a subdomain of one.
  bool isAllowedHost(String host) {
    final h = host.toLowerCase();
    return allowedHosts.any((allowed) => h == allowed || h.endsWith('.$allowed'));
  }

  /// Whether [uri] is the redirect URL [expected]: same scheme, host, port
  /// and path (a trailing slash is ignored); query and fragment are ignored.
  static bool matchesRedirect(Uri uri, Uri expected) {
    return uri.scheme.toLowerCase() == expected.scheme.toLowerCase() &&
        uri.host.toLowerCase() == expected.host.toLowerCase() &&
        uri.port == expected.port &&
        _path(uri) == _path(expected);
  }

  static String _path(Uri uri) {
    final path = uri.path;
    if (path.isEmpty || path == '/') return '/';
    return path.endsWith('/') ? path.substring(0, path.length - 1) : path;
  }
}
