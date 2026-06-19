import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sooq_merchant/config/bootstrap_config.dart';
import 'package:sooq_merchant/config/config_cache.dart';
import 'package:sooq_merchant/config/config_mode.dart';

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('config_cache_test_');
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  ConfigCache cache() => ConfigCache(
    directoryProvider: () async => tempDir,
  );

  const bootstrapA = BootstrapConfig(
    schemaVersion: '1.0',
    configMode: ConfigMode.remoteStorage,
    variantId: 'mobile_production_v2',
    appName: 'Store A',
    bundleId: 'com.store.a',
    apiBaseUrl: 'https://api.example.com',
    tenantSlug: 'store-a',
  );

  const bootstrapB = BootstrapConfig(
    schemaVersion: '1.0',
    configMode: ConfigMode.remoteStorage,
    variantId: 'mobile_production_v2',
    appName: 'Store B',
    bundleId: 'com.store.b',
    apiBaseUrl: 'https://api.example.com',
    tenantSlug: 'store-b',
  );

  test('read on empty directory returns null', () async {
    final result = await cache().read(bootstrapA);
    expect(result, isNull);
  });

  test('write then read round-trips identical string', () async {
    const rawJson = '{"schemaVersion":"1.0","pages":[]}';
    final c = cache();

    await c.write(bootstrapA, rawJson);
    final read = await c.read(bootstrapA);

    expect(read, rawJson);
  });

  test('delete then read returns null', () async {
    final c = cache();
    await c.write(bootstrapA, '{"pages":[]}');
    await c.delete(bootstrapA);

    expect(await c.read(bootstrapA), isNull);
  });

  test('different tenantSlug uses separate files', () async {
    final c = cache();
    await c.write(bootstrapA, '{"tenant":"a"}');
    await c.write(bootstrapB, '{"tenant":"b"}');

    expect(await c.read(bootstrapA), '{"tenant":"a"}');
    expect(await c.read(bootstrapB), '{"tenant":"b"}');
  });
}
