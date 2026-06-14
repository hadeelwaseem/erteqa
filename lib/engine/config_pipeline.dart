import 'package:flutter/foundation.dart';

import '../config/bootstrap_config.dart';
import '../config/config_mode.dart';
import '../config/local_asset_config_source.dart';
import '../config/mobile_app_config.dart';
import 'config_pipeline_result.dart';

/// Orchestrates bootstrap → full config → [MobileAppConfig] at startup.
class ConfigPipeline {
  ConfigPipeline._();

  /// Loads bootstrap, resolves config source, and parses [MobileAppConfig].
  ///
  /// Returns a result with null [ConfigPipelineResult.mobileAppConfig] on failure
  /// so startup can proceed with a safe fallback (same as legacy [AppConfigLoader]).
  static Future<ConfigPipelineResult> initialize() async {
    BootstrapConfig bootstrap;
    try {
      bootstrap = await LocalAssetConfigSource.loadBootstrap(
        allowLocalFallback: kDebugMode,
      );
    } catch (e, st) {
      debugPrint('[ConfigPipeline] ❌ Failed to load bootstrap: $e\n$st');
      return ConfigPipelineResult(
        bootstrap: const BootstrapConfig(
          schemaVersion: '1.0',
          configMode: ConfigMode.local,
          variantId: '',
          appName: 'App',
          bundleId: '',
          apiBaseUrl: '',
        ),
      );
    }

    if (bootstrap.configMode != ConfigMode.local) {
      debugPrint(
        '[ConfigPipeline] ❌ Config mode "${bootstrap.configMode.toJson()}" '
        'is not implemented yet (Sprint 1 supports local only).',
      );
      return ConfigPipelineResult(bootstrap: bootstrap);
    }

    try {
      final source = LocalAssetConfigSource();
      final rawJson = await source.loadFullConfig(bootstrap);
      final mobileConfig = MobileAppConfig.fromJson(
        rawJson,
        bootstrap.variantId,
      );
      debugPrint(
        '[ConfigPipeline] ✅ Loaded config: ${mobileConfig.appName} '
        '(${mobileConfig.navigation.tabs.length} tabs, '
        '${mobileConfig.pageRoutes.length} pages, '
        'mode=${bootstrap.configMode.toJson()}, '
        'variant=${bootstrap.variantId})',
      );
      return ConfigPipelineResult(
        bootstrap: bootstrap,
        mobileAppConfig: mobileConfig,
        rawConfigJson: rawJson,
        usedRemoteConfig: false,
      );
    } catch (e, st) {
      debugPrint('[ConfigPipeline] ❌ Failed to load full config: $e\n$st');
      return ConfigPipelineResult(bootstrap: bootstrap);
    }
  }
}
