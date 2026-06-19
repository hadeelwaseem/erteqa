import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sooq_merchant/config/bootstrap_config.dart';
import 'package:sooq_merchant/config/config_cache.dart';
import 'package:sooq_merchant/config/config_mode.dart';
import 'package:sooq_merchant/config/config_source.dart';
import 'package:sooq_merchant/config/remote_config_fetcher.dart';
import 'package:sooq_merchant/config/session_config_resolver.dart';import 'package:sooq_merchant/engine/config_pipeline_result.dart';
import 'package:sooq_merchant/engine/config_pipeline.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('ConfigPipeline local mode loads prod JSON via bootstrap.local.json', () async {
    final result = await ConfigPipeline.initialize();

    expect(result.bootstrap.configMode, ConfigMode.local);
    expect(result.bootstrap.variantId, 'mobile_production_v2');
    expect(result.usedRemoteConfig, isFalse);

    final mobileConfig = result.mobileAppConfig;
    expect(mobileConfig, isNotNull);
    expect(mobileConfig!.appName, result.bootstrap.appName);
    expect(mobileConfig.tenantSlug, result.bootstrap.tenantSlug);
    expect(mobileConfig.tenantId, result.bootstrap.tenantId);
    expect(mobileConfig.apiBaseUrl, result.bootstrap.apiBaseUrl);
    expect(mobileConfig.navigation.tabs.length, greaterThan(0));
    expect(mobileConfig.pageRoutes.length, greaterThan(0));
    expect(result.rawConfigJson, isNotNull);
    expect(result.rawConfigJson!['pages'], isA<List>());
    expect(result.rawConfigJson!.containsKey('app'), isFalse);
    expect(result.sessionSource, SessionConfigSource.asset);
  });

  test('ConfigPipeline remote mode uses bootstrap identity; ignores legacy app block', () async {
    const bootstrap = BootstrapConfig(
      schemaVersion: '1.0',
      configMode: ConfigMode.remoteStorage,
      variantId: 'remote',
      appName: 'Remote Store',
      bundleId: 'com.remote.store',
      apiBaseUrl: 'https://bootstrap.api.example',
      tenantId: 'bootstrap-tenant',
      tenantSlug: 'bootstrap-slug',
      configUrl: 'https://cdn.example.com/mobile-config.json',
    );

    final result = await ConfigPipeline.initializeWith(
      bootstrapOverride: bootstrap,
      sourceOverride: _FakeRemoteConfigSource(),
    );

    expect(result.usedRemoteConfig, isTrue);
    expect(result.mobileAppConfig, isNotNull);
    expect(result.mobileAppConfig!.appName, 'Remote Store');
    expect(result.mobileAppConfig!.apiBaseUrl, 'https://bootstrap.api.example');
    expect(result.mobileAppConfig!.tenantSlug, 'bootstrap-slug');
    expect(result.mobileAppConfig!.navigation.tabs.length, 1);
    expect(result.rawConfigJson!['pages'], isA<List>());
  });

  test('ConfigPipeline remote mode via resolver sets sessionSource asset on fallback',
      () async {
    const bootstrap = BootstrapConfig(
      schemaVersion: '1.0',
      configMode: ConfigMode.remoteStorage,
      variantId: 'mobile_production_v2',
      appName: 'Remote Store',
      bundleId: 'com.remote.store',
      apiBaseUrl: 'https://bootstrap.api.example',
      tenantSlug: 'bootstrap-slug',
      configUrl: 'https://cdn.example.com/mobile-config.json',
    );

    final tempDir = Directory.systemTemp.createTempSync('pipeline_resolver_test_');
    final cache = ConfigCache(directoryProvider: () async => tempDir);

    final result = await ConfigPipeline.initializeWith(
      bootstrapOverride: bootstrap,
      resolverOverride: SessionConfigResolver(
        cache: cache,
        fetcher: RemoteConfigFetcher(
          client: Dio()
            ..interceptors.add(
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
            ),
        ),
        assetLoader: (_) async => {
          'schemaVersion': '1.0',
          'navigation': {
            'type': 'tabs',
            'initialRoute': '/home',
            'tabs': [
              {'id': 'home', 'label': 'Home', 'icon': 'home', 'route': '/home'},
            ],
          },
          'pages': [
            {
              'id': 'home-page',
              'route': '/home',
              'title': 'Home',
              'body': [
                {
                  'id': 'title',
                  'type': 'text',
                  'props': {'value': 'Hello'},
                },
              ],
            },
          ],
        },
      ),
    );

    expect(result.mobileAppConfig, isNotNull);
    expect(result.sessionSource, SessionConfigSource.asset);
    expect(result.rawConfigJson!['pages'], isA<List>());

    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });
}

class _FakeRemoteConfigSource implements AppConfigSource {
  @override
  Future<Map<String, dynamic>> loadFullConfig(BootstrapConfig bootstrap) async {
    return {
      'schemaVersion': '1.0',
      'theme': {
        'mode': 'light',
        'colors': {'primary': '#000000'},
        'typography': {'fontFamily': 'Tajawal'},
      },
      'navigation': {
        'type': 'tabs',
        'initialRoute': '/home',
        'tabs': [
          {'id': 'home', 'label': 'Home', 'icon': 'home', 'route': '/home'},
        ],
      },
      'pages': [
        {
          'id': 'home-page',
          'route': '/home',
          'title': 'Home',
          'body': [
            {
              'id': 'home-title',
              'type': 'text',
              'props': {'value': 'Hello'},
            },
          ],
        },
      ],
    };
  }
}
