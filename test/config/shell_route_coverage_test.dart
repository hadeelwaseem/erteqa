import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sooq_merchant/config/bootstrap_config.dart';
import 'package:sooq_merchant/config/config_mode.dart';
import 'package:sooq_merchant/config/mobile_app_config.dart';

void main() {
  test('mobile_production_v2 non-tab pages are in shellExcludeRoutes', () {
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

    final tabRoutes =
        config.navigation.tabs.map((t) => t.route).toSet();
    final shellExcludes = config.navigation.shellExcludeRoutes.toSet();

    final nonTabRoutes =
        config.pageRoutes.where((r) => !tabRoutes.contains(r)).toList();

    final missing = nonTabRoutes
        .where((route) => !shellExcludes.contains(route))
        .toList();

    expect(
      missing,
      isEmpty,
      reason:
          'Every page route that is not a tab must be listed in '
          'navigation.shellExcludeRoutes so drill-down screens do not '
          'show the bottom bar. Missing: $missing',
    );
  });
}
