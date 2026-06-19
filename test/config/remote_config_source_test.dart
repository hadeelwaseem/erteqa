import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sooq_merchant/config/bootstrap_config.dart';
import 'package:sooq_merchant/config/config_mode.dart';
import 'package:sooq_merchant/config/remote_config_source.dart';
import 'package:sooq_merchant/config/remote_config_url.dart';

void main() {
  group('resolveRemoteConfigUrl', () {
    test('remoteStorage uses configUrl', () {
      const bootstrap = BootstrapConfig(
        schemaVersion: '1.0',
        configMode: ConfigMode.remoteStorage,
        variantId: 'remote',
        appName: 'App',
        bundleId: 'com.app',
        apiBaseUrl: 'https://api.example.com',
        configUrl: 'https://cdn.example.com/mobile-config.json',
      );

      expect(
        resolveRemoteConfigUrl(bootstrap),
        'https://cdn.example.com/mobile-config.json',
      );
    });

    test('remoteStorage throws when configUrl missing', () {
      const bootstrap = BootstrapConfig(
        schemaVersion: '1.0',
        configMode: ConfigMode.remoteStorage,
        variantId: 'remote',
        appName: 'App',
        bundleId: 'com.app',
        apiBaseUrl: 'https://api.example.com',
      );

      expect(
        () => resolveRemoteConfigUrl(bootstrap),
        throwsA(isA<RemoteConfigException>()),
      );
    });

    test('remoteApi builds public mobile-config URL', () {
      const bootstrap = BootstrapConfig(
        schemaVersion: '1.0',
        configMode: ConfigMode.remoteApi,
        variantId: 'remote',
        appName: 'App',
        bundleId: 'com.app',
        apiBaseUrl: 'https://api.example.com',
        tenantSlug: 'store-a',
      );

      expect(
        resolveRemoteConfigUrl(bootstrap),
        'https://api.example.com/api/v1/public/mobile-config?tenantSlug=store-a',
      );
    });
  });

  group('RemoteConfigSource', () {
    test('loads valid config JSON from HTTP', () async {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: '{"schemaVersion":"1.0","pages":[],"navigation":{}}',
              ),
            );
          },
        ),
      );

      const bootstrap = BootstrapConfig(
        schemaVersion: '1.0',
        configMode: ConfigMode.remoteStorage,
        variantId: 'remote',
        appName: 'App',
        bundleId: 'com.app',
        apiBaseUrl: 'https://api.example.com',
        configUrl: 'https://cdn.example.com/mobile-config.json',
      );

      final source = RemoteConfigSource(client: dio);
      final json = await source.loadFullConfig(bootstrap);

      expect(json['schemaVersion'], '1.0');
      expect(json['pages'], isA<List>());
    });

    test('accepts legacy root object and ignores app block in payload', () async {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data:
                    '{"schemaVersion":"1.0","app":{"name":"Legacy"},'
                    '"root":{"type":"scaffold","child":{"type":"text","props":{"value":"x"}}}}',
              ),
            );
          },
        ),
      );

      const bootstrap = BootstrapConfig(
        schemaVersion: '1.0',
        configMode: ConfigMode.remoteStorage,
        variantId: 'remote',
        appName: 'App',
        bundleId: 'com.app',
        apiBaseUrl: 'https://api.example.com',
        configUrl: 'https://cdn.example.com/mobile-config.json',
      );

      final source = RemoteConfigSource(client: dio);
      final json = await source.loadFullConfig(bootstrap);

      expect(json['root'], isA<Map<String, dynamic>>());
      expect(json['app'], isA<Map<String, dynamic>>());
    });

    test('throws on network failure without cache fallback', () async {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.reject(
              DioException(
                requestOptions: options,
                type: DioExceptionType.connectionError,
                message: 'offline',
              ),
            );
          },
        ),
      );

      const bootstrap = BootstrapConfig(
        schemaVersion: '1.0',
        configMode: ConfigMode.remoteStorage,
        variantId: 'remote',
        appName: 'App',
        bundleId: 'com.app',
        apiBaseUrl: 'https://api.example.com',
        configUrl: 'https://cdn.example.com/mobile-config.json',
      );

      final source = RemoteConfigSource(client: dio);

      expect(
        () => source.loadFullConfig(bootstrap),
        throwsA(
          isA<RemoteConfigException>().having(
            (e) => e.message,
            'message',
            contains('Failed to fetch config'),
          ),
        ),
      );
    });

    test('remoteApi loads config from API URL', () async {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            expect(
              options.uri.toString(),
              'https://api.example.com/api/v1/public/mobile-config?tenantSlug=store-a',
            );
            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: '{"schemaVersion":"1.0","pages":[],"navigation":{}}',
              ),
            );
          },
        ),
      );

      const bootstrap = BootstrapConfig(
        schemaVersion: '1.0',
        configMode: ConfigMode.remoteApi,
        variantId: 'remote',
        appName: 'App',
        bundleId: 'com.app',
        apiBaseUrl: 'https://api.example.com',
        tenantSlug: 'store-a',
      );

      final source = RemoteConfigSource(client: dio);
      final json = await source.loadFullConfig(bootstrap);

      expect(json['pages'], isA<List>());
    });
  });
}
