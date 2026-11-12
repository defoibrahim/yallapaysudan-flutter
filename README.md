# YallaPay Sudan for Dart and Flutter

Dart and Flutter packages for the [YallaPaySudan](https://yallapaysudan.com) payment gateway.

| Package | Where it runs | What it does |
| --- | --- | --- |
| [`yalla_pay_sudan_core`](packages/yalla_pay_sudan_core) | Your **server** (pure Dart, no Flutter) | Creates payment and subscription links, checks payment status, verifies webhook signatures. Holds the API key and webhook secret. |
| [`yalla_pay_sudan`](packages/yalla_pay_sudan) | Your **Flutter app** | Opens the checkout in an in-app WebView and returns a typed result. Holds no secrets. |

> **Keep secrets on the server.** The YallaPaySudan auth token (`sk_...` / `test_sk_...`) and the webhook secret must never be bundled into a mobile or web app: anyone can extract them from an APK or IPA. The app asks your backend for a checkout URL; the backend calls the gateway with `yalla_pay_sudan_core`.

## Screenshots

| Main Screen | Checkout | Payment Success | Result |
| :-: | :-: | :-: | :-: |
| ![Main](https://raw.githubusercontent.com/defoibrahim/yallapaysudan-flutter/main/screenshots/1_main_dark.png) | ![Checkout](https://raw.githubusercontent.com/defoibrahim/yallapaysudan-flutter/main/screenshots/2_checkout.png) | ![Success](https://raw.githubusercontent.com/defoibrahim/yallapaysudan-flutter/main/screenshots/3_payment_succ.png) | ![Result](https://raw.githubusercontent.com/defoibrahim/yallapaysudan-flutter/main/screenshots/4_payment_result.png) |

## Example

[`packages/yalla_pay_sudan/example`](packages/yalla_pay_sudan/example) is a Flutter app that pays through [`example/server`](packages/yalla_pay_sudan/example/server), a small Shelf backend built on `yalla_pay_sudan_core`. The app holds no secrets.

## Development

The Flutter package depends on `yalla_pay_sudan_core` from pub.dev. To work on both together, point it at the local checkout:

```bash
bash tool/dev_overrides.sh          # writes git-ignored pubspec_overrides.yaml files
(cd packages/yalla_pay_sudan_core && dart pub get && dart test)
(cd packages/yalla_pay_sudan && flutter pub get && flutter test)
bash tool/dev_overrides.sh --remove # before publishing
```

CI (`.github/workflows/ci.yml`) runs on every pull request and push to `main`:

- **core:** format, analyze, tests with coverage and the example backend's tests, using only the Dart SDK. This proves core has no Flutter dependency.
- **Flutter package:** format, analyze (package, example app, backend) and widget tests.
- **README samples:** every Dart sample in both package READMEs must appear in a test file that CI analyzes (`tool/ci/check_readme_snippets.py`).
- **pana:** both packages must score 160/160. Until core is on pub.dev, the Flutter package is scored against the current commit's core through a local pub proxy (`tool/ci/local_pub_proxy.py`).
- **Example builds:** Android (APK), iOS (no codesign) and macOS.

## Releasing

Releases are published from GitHub Actions with pub.dev [automated publishing](https://dart.dev/tools/pub/automated-publishing). No credentials are stored in the repository.

1. Bump `version` and `CHANGELOG.md` in the package, merge to `main`, and wait for CI to pass.
2. Publish **`yalla_pay_sudan_core` first**, then **`yalla_pay_sudan`**, which depends on it. Push the tags:
   ```bash
   git tag yalla_pay_sudan_core-v2.0.0 && git push origin yalla_pay_sudan_core-v2.0.0
   git tag yalla_pay_sudan-v2.0.0 && git push origin yalla_pay_sudan-v2.0.0
   ```
3. `.github/workflows/publish.yml` checks that each tag matches the pubspec version, then publishes with `dart-lang/setup-dart`'s reusable workflow.

**One-time setup per package** on pub.dev (package page, **Admin**, **Automated publishing**): enable publishing from GitHub Actions, set repository `defoibrahim/yallapaysudan-flutter`, and set the tag pattern `yalla_pay_sudan_core-v{{version}}` or `yalla_pay_sudan-v{{version}}`. A package that doesn't exist on pub.dev yet (`yalla_pay_sudan_core` before its first release) has no Admin page. Publish it once by hand (`cd packages/yalla_pay_sudan_core && dart pub publish`), then enable automated publishing for later versions.

## License

MIT
