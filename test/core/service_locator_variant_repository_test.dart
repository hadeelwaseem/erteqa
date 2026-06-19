import 'package:flutter_test/flutter_test.dart';
import 'package:sooq_merchant/config/bootstrap_config.dart';
import 'package:sooq_merchant/config/config_mode.dart';
import 'package:sooq_merchant/core/utils/service_locator.dart';
import 'package:sooq_merchant/engine/config_pipeline_result.dart';
import 'package:sooq_merchant/features/variantscreen/data/repos/json_variant_repository.dart';
import 'package:sooq_merchant/features/variantscreen/data/repos/variant_repository.dart';

void main() {
  const bootstrap = BootstrapConfig(
    schemaVersion: '1.0',
    configMode: ConfigMode.local,
    variantId: 'mobile_production_v2',
    appName: 'Test App',
    bundleId: 'com.test.app',
    apiBaseUrl: 'https://api.example.com',
  );

  tearDown(() async {
    await getIt.reset();
  });

  test('registers JsonVariantRepository when rawConfigJson is set (local mode)', () {
    setupServiceLocator(
      pipelineResult: ConfigPipelineResult(
        bootstrap: bootstrap,
        rawConfigJson: {
          'schemaVersion': '1.0',
          'navigation': {'type': 'tabs', 'tabs': []},
          'pages': [],
        },
        usedRemoteConfig: false,
      ),
    );

    expect(getIt<VariantRepository>(), isA<JsonVariantRepository>());
  });

  test('registers AssetVariantRepository when rawConfigJson is null', () {
    setupServiceLocator(
      pipelineResult: ConfigPipelineResult(
        bootstrap: bootstrap,
        rawConfigJson: null,
      ),
    );

    expect(getIt<VariantRepository>(), isA<AssetVariantRepository>());
  });
}
