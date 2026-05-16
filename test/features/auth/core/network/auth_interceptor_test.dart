import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sooq_merchant/core/network/auth_interceptor.dart';
import 'package:sooq_merchant/core/network/network_config.dart';

import '../../support/auth_test_utils.dart';

Dio _createMainDio(FakeHttpClientAdapter adapter) {
  return Dio(BaseOptions(baseUrl: NetworkConfig.defaultBaseUrl))
    ..httpClientAdapter = adapter;
}

void main() {
  group('AuthInterceptor', () {
    test('attaches bearer token on requests', () async {
      final storage = InMemoryAuthTokenStorage()
        ..accessToken = 'access-123'
        ..refreshToken = 'refresh-456';
      final adapter = FakeHttpClientAdapter((options) async {
        expect(options.headers['Authorization'], 'Bearer access-123');
        return jsonResponse({'success': true, 'data': {'ok': true}});
      });

      final dio = _createMainDio(adapter);
      dio.interceptors.add(AuthInterceptor(mainDio: dio, tokenStorage: storage));

      final response = await dio.get('/api/protected');

      expect(response.data['data']['ok'], true);
      expect(adapter.requests, hasLength(1));
    });

    test('refreshes tokens on 401 and retries once', () async {
      final storage = InMemoryAuthTokenStorage()
        ..accessToken = 'access-old'
        ..refreshToken = 'refresh-123';
      var protectedAttempts = 0;
      var refreshAttempts = 0;
      var authLost = false;

      final adapter = FakeHttpClientAdapter((options) async {
        final path = options.path;
        if (path == '/api/protected') {
          protectedAttempts += 1;
          if (protectedAttempts == 1) {
            expect(options.headers['Authorization'], 'Bearer access-old');
            return jsonResponse(
              {'success': false, 'message': 'Unauthorized'},
              statusCode: 401,
            );
          }

          expect(options.headers['Authorization'], 'Bearer access-new');
          return jsonResponse({
            'success': true,
            'data': {'ok': true},
          });
        }

        if (path == '/api/v1/customer/auth/refresh') {
          refreshAttempts += 1;
          expect(options.data, {'refreshToken': 'refresh-123'});
          return jsonResponse({
            'success': true,
            'data': {
              'accessToken': 'access-new',
              'refreshToken': 'refresh-new',
              'tokenType': 'Bearer',
              'expiresIn': 3600,
              'expiresAt': '2026-05-03T13:00:00.000Z',
            },
          });
        }

        throw StateError('Unexpected request: $path');
      });

      final dio = _createMainDio(adapter);
      dio.interceptors.add(
        AuthInterceptor(
          mainDio: dio,
          tokenStorage: storage,
          onAuthLost: () async {
            authLost = true;
            await storage.clearTokens();
          },
        ),
      );

      final response = await dio.get('/api/protected');

      expect(response.data['data']['ok'], true);
      expect(protectedAttempts, 2);
      expect(refreshAttempts, 1);
      expect(authLost, false);
      expect(storage.accessToken, 'access-new');
      expect(storage.refreshToken, 'refresh-new');
      expect(storage.expiresAt, isNotNull);
    });

    test('concurrent 401s trigger a single refresh', () async {
      final storage = InMemoryAuthTokenStorage()
        ..accessToken = 'access-old'
        ..refreshToken = 'refresh-123';
      var refreshAttempts = 0;
      var protectedAttempts = 0;

      final adapter = FakeHttpClientAdapter((options) async {
        final path = options.path;
        if (path == '/api/protected') {
          protectedAttempts += 1;
          if (options.headers['Authorization'] == 'Bearer access-old') {
            return jsonResponse(
              {'success': false, 'message': 'Unauthorized'},
              statusCode: 401,
            );
          }
          return jsonResponse({
            'success': true,
            'data': {'ok': true},
          });
        }

        if (path == '/api/v1/customer/auth/refresh') {
          refreshAttempts += 1;
          await Future<void>.delayed(const Duration(milliseconds: 50));
          return jsonResponse({
            'success': true,
            'data': {
              'accessToken': 'access-new',
              'refreshToken': 'refresh-new',
              'expiresIn': 3600,
            },
          });
        }

        throw StateError('Unexpected path: $path');
      });

      final dio = _createMainDio(adapter);
      dio.interceptors.add(AuthInterceptor(mainDio: dio, tokenStorage: storage));

      final results = await Future.wait([
        dio.get('/api/protected'),
        dio.get('/api/protected'),
      ]);

      expect(results, hasLength(2));
      expect(refreshAttempts, 1);
      expect(protectedAttempts, 4);
      expect(storage.accessToken, 'access-new');
    });

    test('refresh failure invokes onAuthLost and clears tokens', () async {
      final storage = InMemoryAuthTokenStorage()
        ..accessToken = 'access-old'
        ..refreshToken = 'refresh-123';
      var authLost = false;

      final adapter = FakeHttpClientAdapter((options) async {
        if (options.path == '/api/protected') {
          return jsonResponse(
            {'success': false, 'message': 'Unauthorized'},
            statusCode: 401,
          );
        }
        if (options.path == '/api/v1/customer/auth/refresh') {
          return jsonResponse(
            {'success': false, 'message': 'invalid refresh'},
            statusCode: 401,
          );
        }
        throw StateError('Unexpected path: ${options.path}');
      });

      final dio = _createMainDio(adapter);
      dio.interceptors.add(
        AuthInterceptor(
          mainDio: dio,
          tokenStorage: storage,
          onAuthLost: () async {
            authLost = true;
            await storage.clearTokens();
          },
        ),
      );

      await expectLater(
        dio.get('/api/protected'),
        throwsA(isA<DioException>()),
      );

      expect(authLost, true);
      expect(storage.accessToken, isNull);
      expect(storage.refreshToken, isNull);
    });

    test('does not retry non-repeatable request bodies', () async {
      final storage = InMemoryAuthTokenStorage()
        ..accessToken = 'access-old'
        ..refreshToken = 'refresh-123';
      var refreshAttempts = 0;

      final adapter = FakeHttpClientAdapter((options) async {
        if (options.path == '/api/upload') {
          return jsonResponse(
            {'success': false, 'message': 'Unauthorized'},
            statusCode: 401,
          );
        }
        if (options.path == '/api/v1/customer/auth/refresh') {
          refreshAttempts += 1;
          return jsonResponse({
            'success': true,
            'data': {
              'accessToken': 'access-new',
              'refreshToken': 'refresh-new',
            },
          });
        }
        throw StateError('Unexpected path: ${options.path}');
      });

      final dio = _createMainDio(adapter);
      dio.interceptors.add(AuthInterceptor(mainDio: dio, tokenStorage: storage));

      await expectLater(
        dio.post(
          '/api/upload',
          data: FormData.fromMap({'file': 'x'}),
        ),
        throwsA(isA<DioException>()),
      );

      expect(refreshAttempts, 0);
    });
  });
}
