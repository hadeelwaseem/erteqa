import '../config/bootstrap_config.dart';
import '../config/mobile_app_config.dart';

/// Result of [ConfigPipeline.initialize].
class ConfigPipelineResult {
  final BootstrapConfig bootstrap;
  final MobileAppConfig? mobileAppConfig;
  final Map<String, dynamic>? rawConfigJson;
  final bool usedRemoteConfig;

  const ConfigPipelineResult({
    required this.bootstrap,
    this.mobileAppConfig,
    this.rawConfigJson,
    this.usedRemoteConfig = false,
  });
}
