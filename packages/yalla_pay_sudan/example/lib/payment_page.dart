import 'package:material_ui/material_ui.dart';
import 'package:yalla_pay_sudan/yalla_pay_sudan.dart';

import 'checkout_backend.dart';

class PaymentPage extends StatefulWidget {
  final VoidCallback onToggleTheme;

  const PaymentPage({super.key, required this.onToggleTheme});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  // The app holds no YallaPaySudan secrets: the backend in example/server
  // creates the payment and is the source of truth for the order status.
  final _backend = CheckoutBackend();
  bool _loading = false;

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  Future<void> _pay() => _checkout('payment', label: 'Payment');

  Future<void> _subscribe() => _checkout('subscription', label: 'Subscription');

  Future<void> _checkout(String kind, {required String label}) async {
    setState(() => _loading = true);
    try {
      // 1. The backend creates the payment link.
      final session = await _backend.startCheckout(kind);
      if (!mounted) return;

      // 2. The customer pays in the in-app checkout.
      final result = await YallaPayCheckoutWebView.show(
        context,
        paymentUrl: session.paymentUrl,
        successUrl: session.successUrl,
        failedUrl: session.failedUrl,
      );

      // 3. The WebView result is only a hint: ask the backend, which knows
      //    from the verified webhook or the gateway's status API.
      final status = await _backend.orderStatus(session.orderId);
      if (!mounted) return;
      _handleResult(label, result, status);
    } on Exception catch (e) {
      if (mounted) _showSnackBar('$e', type: _SnackType.error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _handleResult(String label, CheckoutResult result, String status) {
    switch (status) {
      case 'successful':
        _showSnackBar('$label successful!', type: _SnackType.success);
      case 'failed' || 'revoked' || 'expired':
        _showSnackBar('$label $status.', type: _SnackType.error);
      case 'cancelled':
        _showSnackBar('$label cancelled.');
      default:
        // Not confirmed yet. A successful redirect usually means the webhook
        // is on its way.
        _showSnackBar(
          result.isSuccessful
              ? '$label received, waiting for confirmation.'
              : 'Checkout closed.',
        );
    }
  }

  // ---------------------------------------------------------------------------
  // Feedback UI
  // ---------------------------------------------------------------------------

  void _showSnackBar(String message, {_SnackType type = _SnackType.info}) {
    final (bgColor, fgColor, icon) = switch (type) {
      _SnackType.success => (
        const Color(0xFFE8F5E9),
        const Color(0xFF2E7D32),
        Icons.check_circle_rounded,
      ),
      _SnackType.error => (
        const Color(0xFFFFEBEE),
        const Color(0xFFC62828),
        Icons.error_rounded,
      ),
      _SnackType.info => (
        const Color(0xFFFFF8E1),
        const Color(0xFFF9A825),
        Icons.warning_rounded,
      ),
    };

    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(icon, color: fgColor, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(color: fgColor, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          backgroundColor: bgColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
          elevation: 0,
          duration: const Duration(seconds: 3),
        ),
      );
  }

  @override
  void dispose() {
    _backend.close();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
          children: [
            // Top bar
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.account_balance_wallet_rounded,
                    size: 28,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                const Spacer(),
                IconButton.filled(
                  onPressed: widget.onToggleTheme,
                  style: IconButton.styleFrom(
                    backgroundColor: colorScheme.surfaceContainer,
                    foregroundColor: colorScheme.onSurface,
                  ),
                  icon: Icon(
                    Theme.of(context).brightness == Brightness.dark
                        ? Icons.light_mode_rounded
                        : Icons.dark_mode_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Header
            Text(
              'YallaPay Sudan',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Payment Gateway SDK Demo',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),

            // One-time payment
            _buildPaymentCard(
              context,
              icon: Icons.bolt_rounded,
              iconColor: colorScheme.primary,
              title: 'One-Time Payment',
              subtitle: 'Pay once for a product or service',
              amount: '5,000 SDG',
              buttonLabel: 'Pay Now',
              onPressed: _pay,
            ),
            const SizedBox(height: 16),

            // Subscription
            _buildPaymentCard(
              context,
              icon: Icons.autorenew_rounded,
              iconColor: colorScheme.tertiary,
              title: 'Monthly Subscription',
              subtitle: '12 monthly billing cycles',
              amount: '3,000 SDG/mo',
              buttonLabel: 'Subscribe',
              outlined: true,
              onPressed: _subscribe,
            ),

            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              ),

            const SizedBox(height: 24),

            // Sandbox info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.science_rounded,
                        size: 18,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Sandbox Mode',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This demo uses the YallaPaySudan sandbox '
                    'environment. No real charges will be made.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String amount,
    required String buttonLabel,
    required VoidCallback onPressed,
    bool outlined = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: outlined ? Border.all(color: colorScheme.outlineVariant) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Text(
                amount,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              SizedBox(
                height: 44,
                child: outlined
                    ? OutlinedButton(
                        onPressed: _loading ? null : onPressed,
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                        ),
                        child: Text(buttonLabel),
                      )
                    : FilledButton(
                        onPressed: _loading ? null : onPressed,
                        style: FilledButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                        ),
                        child: Text(buttonLabel),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

enum _SnackType { success, error, info }
