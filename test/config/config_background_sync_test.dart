import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sooq_merchant/config/bootstrap_config.dart';
import 'package:sooq_merchant/config/config_background_sync.dart';
import 'package:sooq_merchant/config/config_cache.dart';
import 'package:sooq_merchant/config/config_mode.dart';
import 'package:sooq_merchant/config/remote_config_fetcher.dart';
import 'package:sooq_merchant/engine/config_pipeline_result.dart';

void main() {
  const remoteBootstrap = BootstrapConfig(
    schemaVersion: '1.0',
    configMode: ConfigMode.remoteStorage,
    variantId: 'mobile_production_v2',
    appName: 'Remote Store',
    bundleId: 'com.remote.store',
    apiBaseUrl: 'https://api.example.com',
    tenantSlug: 'store-a',
    configUrl: 'https://cdn.example.com/mobile-config.json',
  );

  const localBootstrap = BootstrapConfig(
    schemaVersion: '1.0',
    configMode: ConfigMode.local,
    variantId: 'mobile_production_v2',
    appName: 'Local Store',
    bundleId: 'com.local.store',
    apiBaseUrl: 'https://api.example.com',
    tenantSlug: 'store-a',
  );

  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('bg_sync_test_');
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  ConfigCache cache() => ConfigCache(
    directoryProvider: () async => tempDir,
  );

  String validRawJson() => jsonEncode({
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
  });

  RemoteConfigFetcher fetcherReturning(String? body) {
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (body == null) {
            handler.reject(
              DioException(
                requestOptions: options,
                type: DioExceptionType.connectionError,
              ),
            );
            return;
          }
          handler.resolve(
            Response(
              requestOptions: options,
              statusCode: 200,
              data: body,
            ),
          );
        },
      ),
    );
    return RemoteConfigFetcher(client: dio);
  }

  test('sync returns false for local mode', () async {
    final ok = await ConfigBackgroundSync.sync(localBootstrap);
    expect(ok, isFalse);
  });

  test('sync returns true and writes cache on valid remote fetch', () async {
    final c = cache();
    final raw = validRawJson();

    final ok = await ConfigBackgroundSync.sync(
      remoteBootstrap,
      fetcher: fetcherReturning(raw),
      cache: c,
    );

    expect(ok, isTrue);
    expect(await c.read(remoteBootstrap), raw);
  });

  test('sync returns false when fetch fails', () async {
    final c = cache();

    final ok = await ConfigBackgroundSync.sync(
      remoteBootstrap,
      fetcher: fetcherReturning(null),
      cache: c,
    );

    expect(ok, isFalse);
    expect(await c.read(remoteBootstrap), isNull);
  });

  test('sync returns false and does not write invalid remote JSON', () async {
    final c = cache();

    final ok = await ConfigBackgroundSync.sync(
      remoteBootstrap,
      fetcher: fetcherReturning('{"schemaVersion":"1.0"}'),
      cache: c,
    );

    expect(ok, isFalse);
    expect(await c.read(remoteBootstrap), isNull);
  });

  test('scheduleIfNeeded with local mode does not write cache', () async {
    final c = cache();
    ConfigBackgroundSync.scheduleIfNeeded(
      ConfigPipelineResult(
        bootstrap: localBootstrap,
        rawConfigJson: {'pages': []},
      ),
      fetcher: fetcherReturning(validRawJson()),
      cache: c,
    );

    await Future<void>.delayed(Duration.zero);
    expect(await c.read(localBootstrap), isNull);
  });

  test('scheduleIfNeeded with remote mode does not throw', () async {
    ConfigBackgroundSync.scheduleIfNeeded(
      ConfigPipelineResult(
        bootstrap: remoteBootstrap,
        rawConfigJson: {'pages': []},
      ),
      fetcher: fetcherReturning(null),
      cache: cache(),
    );
    await Future<void>.delayed(Duration.zero);
  });
}
