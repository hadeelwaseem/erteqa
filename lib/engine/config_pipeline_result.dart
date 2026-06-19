import '../config/bootstrap_config.dart';
import '../config/mobile_app_config.dart';

/// Which source supplied the session config at startup.
enum SessionConfigSource { asset, cache, remote }

/// Result of [ConfigPipeline.initialize].
class ConfigPipelineResult {
  final BootstrapConfig bootstrap;
  final MobileAppConfig? mobileAppConfig;

  /// Render-only UI JSON (`theme`, `navigation`, `pages`) as loaded from asset or remote.
  /// Identity is in [bootstrap], not in this map.
  final Map<String, dynamic>? rawConfigJson;
  final bool usedRemoteConfig;

  /// Set by the session resolver (Session 2+). Null until resolver is wired.
  final SessionConfigSource? sessionSource;
  final String? loadError;

  const ConfigPipelineResult({
    required this.bootstrap,
    this.mobileAppConfig,
    this.rawConfigJson,
    this.usedRemoteConfig = false,
    this.sessionSource,
    this.loadError,
  });
}
