import 'package:flutter/foundation.dart';

import '../engine/config_pipeline_result.dart';
import 'bootstrap_config.dart';
import 'config_cache.dart';
import 'config_validator.dart';
import 'local_asset_config_source.dart';
import 'remote_config_fetcher.dart';

/// Successful session config resolution.
class SessionConfigResult {
  final SessionConfigSource sessionSource;
  final Map<String, dynamic> renderJson;
  final String? rawJson;

  const SessionConfigResult({
    required this.sessionSource,
    required this.renderJson,
    this.rawJson,
  });
}

/// Resolves startup config: cache → remote → asset (remote modes),
/// or asset-only with validation (local mode).
class SessionConfigResolver {
  final ConfigCache _cache;
  final RemoteConfigFetcher _fetcher;
  final Future<Map<String, dynamic>> Function(BootstrapConfig bootstrap)
  _assetLoader;

  SessionConfigResolver({
    ConfigCache? cache,
    RemoteConfigFetcher? fetcher,
    Future<Map<String, dynamic>> Function(BootstrapConfig bootstrap)? assetLoader,
  }) : _cache = cache ?? ConfigCache(),
       _fetcher = fetcher ?? RemoteConfigFetcher(),
       _assetLoader =
           assetLoader ?? LocalAssetConfigSource().loadFullConfig;

  /// Local mode: load bundled asset → validate. No cache or remote.
  Future<SessionConfigResult?> resolveLocal(BootstrapConfig bootstrap) async {
    return _resolveAsset(bootstrap, logPrefix: 'local');
  }

  /// Remote modes: cache → remote (timeout) → asset fallback.
  Future<SessionConfigResult?> resolve(
    BootstrapConfig bootstrap, {
    Duration startupRemoteTimeout = const Duration(seconds: 3),
  }) async {
    try {
      final rawCache = await _cache.read(bootstrap);
      if (rawCache != null) {
        final cacheValidation = ConfigValidator.validateString(
          bootstrap,
          rawCache,
        );
        if (cacheValidation.valid && cacheValidation.renderJson != null) {
          debugPrint('[SessionConfigResolver] ✅ Using cached config');
          return SessionConfigResult(
            sessionSource: SessionConfigSource.cache,
            renderJson: cacheValidation.renderJson!,
            rawJson: rawCache,
          );
        }
        debugPrint(
          '[SessionConfigResolver] ⚠️ Invalid cache, deleting: '
          '${cacheValidation.errorMessage}',
        );
        await _cache.delete(bootstrap);
      }
    } catch (e, st) {
      debugPrint(
        '[SessionConfigResolver] ⚠️ Cache read failed, skipping: $e\n$st',
      );
    }

    final rawRemote = await _fetcher.fetch(
      bootstrap,
      timeout: startupRemoteTimeout,
    );
    if (rawRemote != null) {
      final remoteValidation = ConfigValidator.validateString(
        bootstrap,
        rawRemote,
      );
      if (remoteValidation.valid && remoteValidation.renderJson != null) {
        try {
          await _cache.write(bootstrap, rawRemote);
        } catch (e, st) {
          debugPrint(
            '[SessionConfigResolver] ⚠️ Cache write failed (using remote anyway): '
            '$e\n$st',
          );
        }
        debugPrint('[SessionConfigResolver] ✅ Using remote config');
        return SessionConfigResult(
          sessionSource: SessionConfigSource.remote,
          renderJson: remoteValidation.renderJson!,
          rawJson: rawRemote,
        );
      }
      debugPrint(
        '[SessionConfigResolver] ⚠️ Invalid remote config, falling through: '
        '${remoteValidation.errorMessage}',
      );
    } else {
      debugPrint(
        '[SessionConfigResolver] ⚠️ Remote fetch failed or timed out, '
        'trying asset fallback',
      );
    }

    return _resolveAsset(bootstrap, logPrefix: 'remote fallback');
  }

  Future<SessionConfigResult?> _resolveAsset(
    BootstrapConfig bootstrap, {
    required String logPrefix,
  }) async {
    try {
      final renderJson = await _assetLoader(bootstrap);
      final validation = ConfigValidator.validateMap(bootstrap, renderJson);
      if (validation.valid && validation.renderJson != null) {
        debugPrint(
          '[SessionConfigResolver] ✅ Using asset config ($logPrefix)',
        );
        return SessionConfigResult(
          sessionSource: SessionConfigSource.asset,
          renderJson: validation.renderJson!,
        );
      }
      debugPrint(
        '[SessionConfigResolver] ❌ Invalid asset config ($logPrefix): '
        '${validation.errorMessage}',
      );
      return null;
    } catch (e, st) {
      debugPrint(
        '[SessionConfigResolver] ❌ Failed to load asset config ($logPrefix): '
        '$e\n$st',
      );
      return null;
    }
  }
}
