import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../config/local_asset_config_source.dart';
import '../config/mobile_app_config.dart';

/// Loads and parses the top-level mobile app JSON config from assets.
///
/// **Deprecated:** Prefer [ConfigPipeline.initialize] for startup.
/// This helper remains for direct variant-id loading in tests and tooling.
///
/// This reads the JSON only for top-level metadata (navigation, pages routes).
/// Page bodies at runtime load via [JsonVariantRepository] when using
/// [ConfigPipeline.initialize]; this loader is for tests/tooling only.
class AppConfigLoader {
  AppConfigLoader._();

  static const _configPath = 'assets/config';

  /// Loads a [MobileAppConfig] from `assets/config/{variantId}.json`.
  ///
  /// Uses [LocalAssetConfigSource.loadBootstrap] for identity. The asset file
  /// stem is `bootstrap.variantId` when set; otherwise [variantId].
  ///
  /// Returns null on any failure (file missing, parse error) so startup
  /// can proceed with a safe fallback.
  static Future<MobileAppConfig?> load(String variantId) async {
    try {
      final bootstrap = await LocalAssetConfigSource.loadBootstrap(
        allowLocalFallback: kDebugMode,
      );
      final effectiveVariantId = bootstrap.variantId.trim().isNotEmpty
          ? bootstrap.variantId
          : variantId;
      if (effectiveVariantId != variantId) {
        debugPrint(
          '[AppConfigLoader] Using bootstrap.variantId="$effectiveVariantId" '
          '(requested "$variantId")',
        );
      }
      final jsonStr = await rootBundle.loadString(
        '$_configPath/$effectiveVariantId.json',
      );
      final json = jsonDecode(jsonStr) as Map<String, dynamic>;
      final config = MobileAppConfig.fromBootstrapAndRender(
        bootstrap: bootstrap,
        renderJson: json,
      );
      debugPrint(
        '[AppConfigLoader] ✅ Loaded config: ${config.appName} '
        '(${config.navigation.tabs.length} tabs, '
        '${config.pageRoutes.length} pages, '
        'font=${config.theme.typography.fontFamily})',
      );
      return config;
    } catch (e, st) {
      debugPrint('[AppConfigLoader] ❌ Failed to load "$variantId": $e\n$st');
      return null;
    }
  }
}
