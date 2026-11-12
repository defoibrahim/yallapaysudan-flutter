// Every ```dart sample in README.md must appear here verbatim (checked in CI by
// tool/ci/check_readme_snippets.py), so the samples are analyzed and compile.
// ignore_for_file: unused_local_variable

import 'dart:io';

import 'package:test/test.dart';
import 'package:yalla_pay_sudan_core/yalla_pay_sudan_core.dart';

void main() {
  test('README samples compile', () {
    expect(createClient, isA<Function>());
  });
}

late final YallaPayClient client;

YallaPayClient createClient() {
  final client = YallaPayClient(
    YallaPayConfig.sandbox(
      apiKey: Platform.environment['YALLAPAY_API_KEY']!,
      webhookSecret: Platform.environment['YALLAPAY_WEBHOOK_SECRET'],
    ),
  );
  return client;
}

Future<void> createPaymentSample(String orderId) async {
  final response = await client.createPayment(
    PaymentRequest(
      amount: 5000, // SDG, at least PaymentRequest.minimumAmount
      clientReferenceId: orderId, // unique per payment
      description: 'Order $orderId',
      paymentSuccessfulRedirectUrl: 'https://shop.example/payment/success',
      paymentFailedRedirectUrl: 'https://shop.example/payment/failed',
    ),
  );

  // Send these to the app; nothing else.
  final forApp = {
    'paymentUrl': response.paymentUrl,
    'successUrl': response.successRedirectUrl,
    'failedUrl': response.failedRedirectUrl,
  };
}

Future<void> subscriptionSample(String subscriptionId) async {
  final response = await client.createSubscription(
    SubscriptionRequest(
      amount: 3000,
      clientReferenceId: subscriptionId,
      description: 'Monthly plan',
      subscriptionConfiguration: const SubscriptionConfiguration(
        interval: SubscriptionInterval.month,
        intervalCycle: 1, // every month
        totalCycles: 12, // omit for no end date
      ),
    ),
  );
}

Future<void> statusSample(String orderId) async {
  final status = await client.getPaymentStatus(
    clientReferenceId: orderId,
    transactionDate: DateTime(2026, 4, 2), // the day the payment was created
  );

  switch (status.status) {
    case PaymentStatus.successful:
      print('Paid ${status.amount} SDG, ref ${status.paymentReferenceId}');
    case PaymentStatus.failed ||
        PaymentStatus.cancelled ||
        PaymentStatus.revoked ||
        PaymentStatus.expired:
      print('Not paid: ${status.status.name}');
    case PaymentStatus.unknown:
      print('New gateway status ${status.rawStatus}; check again later');
  }
}

Future<int> handleWebhook(
  Map<String, String> headers,
  List<int> rawBody,
) async {
  try {
    final payload = client.verifyWebhookBytes(
      signature: headers['yallapay-signature'] ?? '',
      timestamp: headers['yallapay-timestamp'] ?? '',
      body: rawBody,
    );
    if (await alreadyProcessed(payload.paymentReferenceId, payload.status)) {
      return 200; // a repeated delivery
    }
    switch (payload.status) {
      case PaymentStatus.successful:
        await markOrderPaid(payload.clientReferenceId);
      case PaymentStatus.failed ||
          PaymentStatus.cancelled ||
          PaymentStatus.revoked ||
          PaymentStatus.expired:
        await markOrderUnpaid(payload.clientReferenceId, payload.status);
      case PaymentStatus.unknown:
        await flagForReview(payload.clientReferenceId, payload.rawStatus);
    }
    return 200;
  } on InvalidSignatureException {
    return 401; // forged, altered or stale: ignore it
  } on InvalidResponseException {
    return 400; // correctly signed but not a valid payload
  }
}

Future<void> errorsSample(PaymentRequest request) async {
  try {
    await client.createPayment(request);
  } on YallaPayException catch (e) {
    switch (e) {
      case DuplicateReferenceException():
        // Already used: an earlier attempt may have succeeded. Look it up.
        break;
      case PaymentException(:final responseCode):
        print('Rejected by the gateway ($responseCode): ${e.message}');
      case NetworkException(isTimeout: true):
        // It may have reached the gateway: check getPaymentStatus before
        // creating a new reference for the same order.
        break;
      case NetworkException():
        print('Could not reach the gateway: ${e.message}');
      case InvalidResponseException():
        print('Unreadable gateway response: ${e.message}');
      case InvalidSignatureException():
        break; // only thrown by webhook verification
    }
  }
}

// Stand-ins for the application code the samples call.
Future<bool> alreadyProcessed(String paymentReference, PaymentStatus s) async =>
    false;
Future<void> markOrderPaid(String orderId) async {}
Future<void> markOrderUnpaid(String orderId, PaymentStatus status) async {}
Future<void> flagForReview(String orderId, String rawStatus) async {}
