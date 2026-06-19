import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sooq_merchant/config/bootstrap_config.dart';
import 'package:sooq_merchant/config/config_mode.dart';
import 'package:sooq_merchant/config/config_validator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('split_config strip output passes ConfigValidator', () async {
    final jsonStr = await rootBundle.loadString(
      'assets/config/mobile_production_v2.json',
    );
    final data = jsonDecode(jsonStr) as Map<String, dynamic>;

    // Same strip logic as tool/split_config.dart
    final output = <String, dynamic>{
      'schemaVersion': data['schemaVersion'] ?? '1.0',
      if (data.containsKey('theme')) 'theme': data['theme'],
      if (data.containsKey('navigation')) 'navigation': data['navigation'],
      if (data.containsKey('pages')) 'pages': data['pages'],
    };

    expect(output.containsKey('app'), isFalse);

    const bootstrap = BootstrapConfig(
      schemaVersion: '1.0',
      configMode: ConfigMode.remoteStorage,
      variantId: 'mobile_production_v2',
      appName: 'Anas Golden Store',
      bundleId: 'com.anasgoldenmer.shop',
      apiBaseUrl: 'https://sooq.up.railway.app',
      tenantId: '3fc183e8-ac80-4b2a-8bf1-4cd6ac6ffcb1',
      tenantSlug: 'anasgoldenmer',
      configUrl: 'https://cdn.example.com/mobile-config.json',
    );

    final result = ConfigValidator.validateMap(bootstrap, output);

    expect(result.valid, isTrue, reason: result.errorMessage);
    expect(result.renderJson!['pages'], isA<List>());
  });
}
