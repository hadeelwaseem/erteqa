import 'config_mode.dart';

/// Build-time bootstrap injected per merchant (CI) or dev template.
///
/// Loaded from `assets/config/bootstrap.json` (release/CI) or
/// `assets/config/bootstrap.local.json` (debug fallback).
class BootstrapConfig {
  final String schemaVersion;
  final ConfigMode configMode;
  final String variantId;
  final String appName;
  final String bundleId;
  final String apiBaseUrl;
  final String? tenantId;
  final String? tenantSlug;
  final String? configUrl;
  final String? iconUrl;

  const BootstrapConfig({
    required this.schemaVersion,
    required this.configMode,
    required this.variantId,
    required this.appName,
    required this.bundleId,
    required this.apiBaseUrl,
    this.tenantId,
    this.tenantSlug,
    this.configUrl,
    this.iconUrl,
  });

  factory BootstrapConfig.fromJson(Map<String, dynamic> json) {
    return BootstrapConfig(
      schemaVersion: json['schemaVersion'] as String? ?? '1.0',
      configMode: ConfigMode.fromJson(json['configMode'] as String?),
      variantId: json['variantId'] as String? ?? '',
      appName: json['appName'] as String? ?? 'App',
      bundleId: json['bundleId'] as String? ?? '',
      apiBaseUrl: json['apiBaseUrl'] as String? ?? '',
      tenantId: _optionalString(json['tenantId']),
      tenantSlug: _optionalString(json['tenantSlug']),
      configUrl: _optionalString(json['configUrl']),
      iconUrl: _optionalString(json['iconUrl']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'schemaVersion': schemaVersion,
      'configMode': configMode.toJson(),
      'variantId': variantId,
      'appName': appName,
      'bundleId': bundleId,
      'apiBaseUrl': apiBaseUrl,
      if (tenantId != null) 'tenantId': tenantId,
      if (tenantSlug != null) 'tenantSlug': tenantSlug,
      if (configUrl != null) 'configUrl': configUrl,
      if (iconUrl != null) 'iconUrl': iconUrl,
    };
  }

  static String? _optionalString(Object? value) {
    if (value == null) return null;
    final trimmed = value.toString().trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
