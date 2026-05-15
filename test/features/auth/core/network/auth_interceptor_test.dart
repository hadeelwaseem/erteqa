import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sooq_merchant/core/network/auth_interceptor.dart';
import 'package:sooq_merchant/core/utils/constants.dart';

import '../../support/auth_test_utils.dart';

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

      final dio = Dio()..httpClientAdapter = adapter;
      dio.interceptors.add(AuthInterceptor(tokenStorage: storage));

      final response = await dio.get('$kBaseUrl/api/protected');

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
        final path = options.uri.toString();
        if (path == '$kBaseUrl/api/protected') {
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

        if (path == '$kBaseUrl/api/v1/customer/auth/refresh') {
          refreshAttempts += 1;
          expect(options.data, {'refreshToken': 'refresh-123'});
          return jsonResponse({
            'success': true,
            'data': {
              'accessToken': 'access-new',
              'refreshToken': 'refresh-new',
              'tokenType': 'Bearer',
              'expiresIn': 3600,
            },
          });
        }

        throw StateError('Unexpected request: $path');
      });

      final mainDio = Dio()..httpClientAdapter = adapter;
      final refreshDio = Dio()..httpClientAdapter = adapter;
      mainDio.interceptors.add(
        AuthInterceptor(
          tokenStorage: storage,
          refreshClient: refreshDio,
          onAuthLost: () async {
            authLost = true;
            await storage.clearTokens();
          },
        ),
      );

      final response = await mainDio.get('$kBaseUrl/api/protected');

      expect(response.data['data']['ok'], true);
      expect(protectedAttempts, 2);
      expect(refreshAttempts, 1);
      expect(authLost, false);
      expect(storage.accessToken, 'access-new');
      expect(storage.refreshToken, 'refresh-new');
    });
  });
}