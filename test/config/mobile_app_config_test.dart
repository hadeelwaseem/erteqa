import 'package:flutter_test/flutter_test.dart';
import 'package:sooq_merchant/config/bootstrap_config.dart';
import 'package:sooq_merchant/config/config_mode.dart';
import 'package:sooq_merchant/config/mobile_app_config.dart';
import 'package:sooq_merchant/core/network/network_config.dart';

void main() {
  test('MobileAppConfig.fromBootstrapAndRender uses bootstrap identity only', () {
    const bootstrap = BootstrapConfig(
      schemaVersion: '1.0',
      configMode: ConfigMode.local,
      variantId: 'test_variant',
      appName: 'Test App',
      bundleId: 'com.test.app',
      apiBaseUrl: 'https://api.example.com',
      tenantId: 'tenant-uuid-1',
      tenantSlug: 'store-a',
    );

    final config = MobileAppConfig.fromBootstrapAndRender(
      bootstrap: bootstrap,
      renderJson: {
        'schemaVersion': '1.0',
        'navigation': {
          'type': 'tabs',
          'initialRoute': '/',
          'tabs': [],
        },
        'pages': [],
      },
    );

    expect(config.apiBaseUrl, 'https://api.example.com');
    expect(config.tenantId, 'tenant-uuid-1');
    expect(config.tenantSlug, 'store-a');
    expect(config.appName, 'Test App');
    expect(config.supportWhatsApp, isNull);
    expect(config.supportPhone, isNull);

    final network = NetworkConfig.fromAppConfig(
      apiBaseUrl: config.apiBaseUrl,
      tenantId: config.tenantId,
      tenantSlug: config.tenantSlug,
    );
    expect(network.baseUrl, 'https://api.example.com');
    expect(network.tenantId, 'tenant-uuid-1');
    expect(network.tenantSlug, 'store-a');
    expect(network.effectiveTenantId(), 'tenant-uuid-1');
  });

  test('fromBootstrapAndRender ignores legacy app block in render JSON', () {
    const bootstrap = BootstrapConfig(
      schemaVersion: '1.0',
      configMode: ConfigMode.local,
      variantId: 'test_variant',
      appName: 'Bootstrap Name',
      bundleId: 'com.bootstrap',
      apiBaseUrl: 'https://bootstrap.example',
      tenantSlug: 'bootstrap-slug',
    );

    final config = MobileAppConfig.fromBootstrapAndRender(
      bootstrap: bootstrap,
      renderJson: {
        'schemaVersion': '1.0',
        'app': {
          'name': 'Legacy App',
          'bundleId': 'com.legacy',
          'apiBaseUrl': 'https://legacy.example',
          'tenantSlug': 'legacy-slug',
          'supportWhatsApp': '123',
        },
        'navigation': {
          'type': 'tabs',
          'initialRoute': '/',
          'tabs': [],
        },
        'pages': [],
      },
    );

    expect(config.appName, 'Bootstrap Name');
    expect(config.apiBaseUrl, 'https://bootstrap.example');
    expect(config.tenantSlug, 'bootstrap-slug');
    expect(config.supportWhatsApp, isNull);
  });
}
