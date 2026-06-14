import 'package:flutter_test/flutter_test.dart';
import 'package:sooq_merchant/config/bootstrap_config.dart';
import 'package:sooq_merchant/config/config_mode.dart';

void main() {
  group('ConfigMode', () {
    test('fromJson parses all modes', () {
      expect(ConfigMode.fromJson('local'), ConfigMode.local);
      expect(ConfigMode.fromJson('remoteStorage'), ConfigMode.remoteStorage);
      expect(ConfigMode.fromJson('remoteApi'), ConfigMode.remoteApi);
      expect(ConfigMode.fromJson(null), ConfigMode.local);
      expect(ConfigMode.fromJson('unknown'), ConfigMode.local);
    });

    test('toJson round-trips', () {
      for (final mode in ConfigMode.values) {
        expect(ConfigMode.fromJson(mode.toJson()), mode);
      }
    });
  });

  group('BootstrapConfig', () {
    test('fromJson parses required and optional fields', () {
      final config = BootstrapConfig.fromJson({
        'schemaVersion': '1.0',
        'configMode': 'local',
        'variantId': 'mobile_production_v2',
        'appName': 'SOOQ Merchant Mobile',
        'bundleId': 'com.sooq.merchant.mobile',
        'apiBaseUrl': 'https://sooq.up.railway.app',
        'tenantId': 'tenant-uuid',
        'tenantSlug': 'store-a',
        'configUrl': null,
        'iconUrl': null,
      });

      expect(config.schemaVersion, '1.0');
      expect(config.configMode, ConfigMode.local);
      expect(config.variantId, 'mobile_production_v2');
      expect(config.appName, 'SOOQ Merchant Mobile');
      expect(config.bundleId, 'com.sooq.merchant.mobile');
      expect(config.apiBaseUrl, 'https://sooq.up.railway.app');
      expect(config.tenantId, 'tenant-uuid');
      expect(config.tenantSlug, 'store-a');
      expect(config.configUrl, isNull);
      expect(config.iconUrl, isNull);
    });

    test('toJson includes non-null optional fields', () {
      final config = BootstrapConfig.fromJson({
        'configMode': 'remoteStorage',
        'variantId': 'mobile_production_v2',
        'appName': 'Test',
        'bundleId': 'com.test.app',
        'apiBaseUrl': 'https://api.example.com',
        'configUrl': 'https://cdn.example.com/config.json',
        'iconUrl': 'https://cdn.example.com/icon.png',
      });

      final json = config.toJson();
      expect(json['configMode'], 'remoteStorage');
      expect(json['configUrl'], 'https://cdn.example.com/config.json');
      expect(json['iconUrl'], 'https://cdn.example.com/icon.png');
    });

    test('empty optional strings become null', () {
      final config = BootstrapConfig.fromJson({
        'configMode': 'local',
        'variantId': 'v1',
        'appName': 'App',
        'bundleId': 'com.app',
        'apiBaseUrl': 'https://api.example.com',
        'tenantId': '  ',
        'tenantSlug': '',
      });

      expect(config.tenantId, isNull);
      expect(config.tenantSlug, isNull);
    });
  });
}
