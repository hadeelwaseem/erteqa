import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../config/mobile_app_config.dart';

/// Loads and parses the top-level mobile app JSON config from assets.
///
/// Call once at startup before router setup:
/// ```dart
/// final config = await AppConfigLoader.load('mobile_component_flow_demo');
/// ```
///
/// This reads the JSON only for top-level metadata (navigation, pages routes).
/// Individual page bodies are loaded on demand by [AssetVariantRepository].
class AppConfigLoader {
  AppConfigLoader._();

  static const _configPath = 'assets/config';

  /// Loads a [MobileAppConfig] from `assets/config/$variantId.json`.
  ///
  /// Returns null on any failure (file missing, parse error) so startup
  /// can proceed with a safe fallback.
  static Future<MobileAppConfig?> load(String variantId) async {
    try {
      final jsonStr = await rootBundle.loadString(
        '$_configPath/$variantId.json',
      );
      final json = jsonDecode(jsonStr) as Map<String, dynamic>;
      final config = MobileAppConfig.fromJson(json, variantId);
      debugPrint(
        '[AppConfigLoader] ✅ Loaded config: ${config.appName} '
        '(${config.navigation.tabs.length} tabs, '
        '${config.pageRoutes.length} pages)',
      );
      return config;
    } catch (e, st) {
      debugPrint('[AppConfigLoader] ❌ Failed to load "$variantId": $e\n$st');
      return null;
    }
  }
}
