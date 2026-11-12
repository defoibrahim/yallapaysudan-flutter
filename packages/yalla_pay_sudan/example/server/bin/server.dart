import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:yalla_pay_sudan_core/yalla_pay_sudan_core.dart';
import 'package:yalla_pay_sudan_example_server/checkout_server.dart';

/// Runs the example checkout backend. Secrets come from the environment.
Future<void> main() async {
  final apiKey = Platform.environment['YALLAPAY_API_KEY'] ?? '';
  if (apiKey.isEmpty) {
    stderr.writeln(
      'Set YALLAPAY_API_KEY to your sandbox auth token (test_sk_...).',
    );
    exit(64);
  }
  final webhookSecret = Platform.environment['YALLAPAY_WEBHOOK_SECRET'];

  final client = YallaPayClient(
    YallaPayConfig.sandbox(
      apiKey: apiKey,
      webhookSecret: (webhookSecret?.isEmpty ?? true) ? null : webhookSecret,
    ),
  );
  final app = CheckoutServer(client: client);
  final port = int.tryParse(Platform.environment['PORT'] ?? '') ?? 8080;

  // Listens on all interfaces so an emulator or a phone on the same network
  // can reach it during development.
  final server = await shelf_io.serve(
    const Pipeline().addMiddleware(logRequests()).addHandler(app.handler),
    InternetAddress.anyIPv4,
    port,
  );
  stdout.writeln('Checkout backend listening on port ${server.port}');
}
