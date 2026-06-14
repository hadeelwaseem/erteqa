import 'dart:convert';

import 'package:flutter/services.dart';

import 'bootstrap_config.dart';
import 'config_source.dart';

/// Loads bootstrap and full config from bundled Flutter assets.
class LocalAssetConfigSource implements AppConfigSource {
  static const bootstrapPath = 'assets/config/bootstrap.json';
  static const bootstrapLocalPath = 'assets/config/bootstrap.local.json';
  static const configPathPrefix = 'assets/config';

  /// Loads [BootstrapConfig] from asset bundle.
  ///
  /// Resolution order:
  /// 1. `assets/config/bootstrap.json`
  /// 2. `assets/config/bootstrap.local.json` (when [allowLocalFallback] is true)
  static Future<BootstrapConfig> loadBootstrap({
    bool allowLocalFallback = false,
  }) async {
    final primary = await _tryLoadBootstrapAsset(bootstrapPath);
    if (primary != null) {
      return primary;
    }
    if (allowLocalFallback) {
      final fallback = await _tryLoadBootstrapAsset(bootstrapLocalPath);
      if (fallback != null) {
        return fallback;
      }
    }
    throw StateError(
      'Bootstrap config not found. Expected $bootstrapPath'
      '${allowLocalFallback ? ' or $bootstrapLocalPath' : ''}.',
    );
  }

  static Future<BootstrapConfig?> _tryLoadBootstrapAsset(String path) async {
    try {
      final jsonStr = await rootBundle.loadString(path);
      final json = jsonDecode(jsonStr) as Map<String, dynamic>;
      return BootstrapConfig.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Map<String, dynamic>> loadFullConfig(BootstrapConfig bootstrap) async {
    final variantId = bootstrap.variantId.trim();
    if (variantId.isEmpty) {
      throw ArgumentError('Bootstrap variantId must not be empty.');
    }

    final path = '$configPathPrefix/$variantId.json';
    try {
      final jsonStr = await rootBundle.loadString(path);
      return jsonDecode(jsonStr) as Map<String, dynamic>;
    } catch (e) {
      throw StateError('Failed to load config asset "$path": $e');
    }
  }
}
