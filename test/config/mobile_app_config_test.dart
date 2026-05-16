import 'package:flutter_test/flutter_test.dart';
import 'package:sooq_merchant/config/mobile_app_config.dart';
import 'package:sooq_merchant/core/network/network_config.dart';

void main() {
  test('MobileAppConfig parses apiBaseUrl and tenantSlug from app block', () {
    final config = MobileAppConfig.fromJson(
      {
        'schemaVersion': '1.0',
        'app': {
          'name': 'Test App',
          'bundleId': 'com.test.app',
          'apiBaseUrl': 'https://api.example.com',
          'tenantSlug': 'store-a',
        },
        'navigation': {
          'type': 'tabs',
          'initialRoute': '/',
          'tabs': [],
        },
        'pages': [],
      },
      'test_variant',
    );

    expect(config.apiBaseUrl, 'https://api.example.com');
    expect(config.tenantSlug, 'store-a');

    final network = NetworkConfig.fromAppConfig(
      apiBaseUrl: config.apiBaseUrl,
      tenantSlug: config.tenantSlug,
    );
    expect(network.baseUrl, 'https://api.example.com');
    expect(network.tenantSlug, 'store-a');
  });
}
