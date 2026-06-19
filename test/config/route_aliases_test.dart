import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sooq_merchant/config/bootstrap_config.dart';
import 'package:sooq_merchant/config/config_mode.dart';
import 'package:sooq_merchant/config/mobile_app_config.dart';

void main() {
  test('mobile_production_v2 registers alias routes and excludes them from shell',
      () {
    final jsonFile = File('assets/config/mobile_production_v2.json');
    final json =
        jsonDecode(jsonFile.readAsStringSync()) as Map<String, dynamic>;
    const bootstrap = BootstrapConfig(
      schemaVersion: '1.0',
      configMode: ConfigMode.local,
      variantId: 'mobile_production_v2',
      appName: 'Test',
      bundleId: 'com.test',
      apiBaseUrl: 'https://example.com',
    );
    final config = MobileAppConfig.fromBootstrapAndRender(
      bootstrap: bootstrap,
      renderJson: json,
    );

    expect(config.navigation.routeAliases['/categories/browse'], '/categories');
    expect(config.pageRoutes, contains('/categories/browse'));
    expect(
      config.navigation.shellExcludeRoutes,
      contains('/categories/browse'),
    );
  });
}
