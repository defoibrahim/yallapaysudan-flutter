import 'package:dio/dio.dart';
import 'package:test/test.dart';
import 'package:yalla_pay_sudan_core/src/interceptors/auth_interceptor.dart';
import 'package:yalla_pay_sudan_core/src/interceptors/logging_interceptor.dart';

import '../support/fake_http.dart';

void main() {
  const token = 'sk_live_do_not_log_me';

  test('AuthInterceptor sends the bearer token and JSON headers', () async {
    final adapter = FakeAdapter((_) => jsonResponse({'ok': true}));
    final dio = fakeDio(adapter)..interceptors.add(AuthInterceptor(token));

    await dio.post<Object?>('/x', data: {'a': 1});

    final headers = adapter.requests.single.headers;
    expect(headers['Authorization'], 'Bearer $token');
    expect(headers['Accept'], 'application/json');
    expect(adapter.requests.single.contentType, contains('application/json'));
  });

  group('YallaPayLoggingInterceptor', () {
    late List<String> lines;
    late FakeAdapter adapter;
    late Dio dio;

    setUp(() {
      lines = [];
      adapter = FakeAdapter((_) => jsonResponse({'ok': true}));
      dio = fakeDio(adapter)
        ..interceptors.addAll([
          AuthInterceptor(token),
          YallaPayLoggingInterceptor(log: lines.add),
        ]);
    });

    test('logs requests and responses but never the token', () async {
      await dio.post<Object?>('/pay', data: {'amount': 5000});

      expect(lines, hasLength(2));
      expect(lines.first, contains('REQUEST[POST] => /pay'));
      expect(lines.first, contains('5000'));
      expect(lines.last, contains('RESPONSE[200]'));
      expect(lines.join('\n'), isNot(contains(token)));
      expect(lines.join('\n'), isNot(contains('Authorization')));
    });

    test('logs errors without the token', () async {
      adapter.handler = (_) =>
          jsonResponse({'responseMessage': 'nope'}, status: 401);

      await expectLater(
        dio.post<Object?>('/pay', data: {'amount': 5000}),
        throwsA(isA<DioException>()),
      );

      expect(lines.last, contains('ERROR[401]'));
      expect(lines.last, contains('nope'));
      expect(lines.join('\n'), isNot(contains(token)));
    });
  });
}
