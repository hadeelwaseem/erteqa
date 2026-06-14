import 'package:flutter_test/flutter_test.dart';
import 'package:sooq_merchant/config/config_mode.dart';
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
    expect(mobileConfig!.appName, 'SOOQ Merchant Mobile');
    expect(mobileConfig.tenantSlug, 'anasgoldenmer');
    expect(mobileConfig.tenantId, '3fc183e8-ac80-4b2a-8bf1-4cd6ac6ffcb1');
    expect(mobileConfig.navigation.tabs.length, greaterThan(0));
    expect(mobileConfig.pageRoutes.length, greaterThan(0));
    expect(result.rawConfigJson, isNotNull);
    expect(result.rawConfigJson!['pages'], isA<List>());
  });
}
