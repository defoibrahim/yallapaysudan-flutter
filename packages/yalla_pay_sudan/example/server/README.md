# Example checkout backend

A small [Shelf](https://pub.dev/packages/shelf) server that shows where the YallaPaySudan secrets belong: **here, not in the app**. The example app calls it to start a checkout and to read the order status.

| Endpoint | What it does |
| --- | --- |
| `POST /checkout` with `{"kind": "payment"}` or `{"kind": "subscription"}` | Creates the payment link with `yalla_pay_sudan_core` and returns `orderId`, `paymentUrl`, `successUrl`, `failedUrl`. |
| `GET /orders/<orderId>` | The order status as the server knows it: from a verified webhook, or by asking the gateway (`getPaymentStatus`). |
| `POST /webhooks/yallapay` | Verifies the webhook signature over the raw body and updates the order. |

## Run

```bash
# From the repository root, until yalla_pay_sudan_core is on pub.dev:
bash tool/dev_overrides.sh

cd packages/yalla_pay_sudan/example/server
dart pub get
YALLAPAY_API_KEY=test_sk_... YALLAPAY_WEBHOOK_SECRET=... dart run bin/server.dart
```

The server listens on port 8080 (`PORT` to change it). Then run the app; it looks for the backend at `http://10.0.2.2:8080` on the Android emulator and `http://localhost:8080` elsewhere. Override this with `--dart-define=CHECKOUT_BACKEND_URL=http://<host>:8080`.

Orders are kept in memory, and the HTTP endpoints have no authentication. This is a reference for local development, not a production server.
