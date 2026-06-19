import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sooq_merchant/config/bootstrap_config.dart';
import 'package:sooq_merchant/config/config_mode.dart';
import 'package:sooq_merchant/config/remote_config_fetcher.dart';

void main() {
  const bootstrap = BootstrapConfig(
    schemaVersion: '1.0',
    configMode: ConfigMode.remoteStorage,
    variantId: 'remote',
    appName: 'App',
    bundleId: 'com.app',
    apiBaseUrl: 'https://api.example.com',
    configUrl: 'https://cdn.example.com/mobile-config.json',
  );

  test('fetch returns body on HTTP 200', () async {
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.resolve(
            Response(
              requestOptions: options,
              statusCode: 200,
              data: '{"schemaVersion":"1.0","pages":[]}',
            ),
          );
        },
      ),
    );

    final body = await RemoteConfigFetcher(client: dio).fetch(
      bootstrap,
      timeout: const Duration(seconds: 3),
    );

    expect(body, contains('"pages"'));
  });

  test('fetch returns null on HTTP 404', () async {
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.resolve(
            Response(
              requestOptions: options,
              statusCode: 404,
              data: 'not found',
            ),
          );
        },
      ),
    );

    final body = await RemoteConfigFetcher(client: dio).fetch(
      bootstrap,
      timeout: const Duration(seconds: 3),
    );

    expect(body, isNull);
  });

  test('fetch returns null on network failure', () async {
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.reject(
            DioException(
              requestOptions: options,
              type: DioExceptionType.connectionError,
            ),
          );
        },
      ),
    );

    final body = await RemoteConfigFetcher(client: dio).fetch(
      bootstrap,
      timeout: const Duration(seconds: 3),
    );

    expect(body, isNull);
  });

  test('fetch returns null when body is not a JSON object', () async {
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.resolve(
            Response(
              requestOptions: options,
              statusCode: 200,
              data: '["array"]',
            ),
          );
        },
      ),
    );

    final body = await RemoteConfigFetcher(client: dio).fetch(
      bootstrap,
      timeout: const Duration(seconds: 3),
    );

    expect(body, isNull);
  });
}
