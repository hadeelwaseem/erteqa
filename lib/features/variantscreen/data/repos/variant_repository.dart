import 'dart:convert';

import 'package:flutter/services.dart';

import '../../../../config/screen_config.dart';
import 'variant_config_parser.dart';

export 'variant_config_parser.dart' show resolvePagePadding;

/// Abstract repository for loading dynamic screen configurations.
///
/// **Responsibility**: Load and parse [ScreenConfig] from a data source.
///
/// **Current implementation**: [JsonVariantRepository] loads from session-resolved
/// in-memory JSON when the config pipeline provides [rawConfigJson].
/// [AssetVariantRepository] loads from JSON files in assets (dev `/variant/:id` route).
abstract class VariantRepository {
  /// Load screen config by pageId.
  ///
  /// **Parameters**:
  /// - [variantId]: The pageId (e.g., 'classic', 'dashboard', 'modern')
  ///
  /// **Returns**: Fully parsed [ScreenConfig] with pageId, pageName, and root component tree.
  ///
  /// **Throws**: Exception if config cannot be found or parsed.
  /// Error is caught by [VariantCubit] and emitted as [VariantFailure].
  Future<ScreenConfig> loadVariant(String variantId, {String? pageRoute});
}

/// Loads screen configs from JSON asset files.
///
/// **Dev / tests only** — used by the `/variant/:id` dev route and tests that
/// construct the repository directly. Normal app startup uses
/// [JsonVariantRepository] via DI when [ConfigPipelineResult.rawConfigJson] is set.
///
/// **Pattern**: Deterministic, stateless loading from `assets/config/{pageId}.json`
class AssetVariantRepository implements VariantRepository {
  static const _configPath = 'assets/config';

  @override
  Future<ScreenConfig> loadVariant(
    String variantId, {
    String? pageRoute,
  }) async {
    final jsonString = await rootBundle.loadString(
      '$_configPath/$variantId.json',
    );
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    return VariantConfigParser.parseFromRoot(
      json,
      variantId,
      pageRoute: pageRoute,
    );
  }
}
