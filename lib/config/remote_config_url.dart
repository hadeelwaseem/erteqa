import 'bootstrap_config.dart';
import 'config_mode.dart';

/// Thrown when remote config cannot be loaded.
class RemoteConfigException implements Exception {
  final String message;

  const RemoteConfigException(this.message);

  @override
  String toString() => 'RemoteConfigException: $message';
}

/// Resolves the fetch URL for a bootstrap [configMode].
String resolveRemoteConfigUrl(BootstrapConfig bootstrap) {
  switch (bootstrap.configMode) {
    case ConfigMode.remoteStorage:
      final url = bootstrap.configUrl?.trim();
      if (url == null || url.isEmpty) {
        throw const RemoteConfigException(
          'configUrl is required when configMode is remoteStorage.',
        );
      }
      return url;
    case ConfigMode.remoteApi:
      final slug = bootstrap.tenantSlug?.trim();
      final base = bootstrap.apiBaseUrl.trim();
      if (base.isEmpty) {
        throw const RemoteConfigException(
          'apiBaseUrl is required when configMode is remoteApi.',
        );
      }
      if (slug == null || slug.isEmpty) {
        throw const RemoteConfigException(
          'tenantSlug is required when configMode is remoteApi.',
        );
      }
      final normalizedBase = base.endsWith('/')
          ? base.substring(0, base.length - 1)
          : base;
      return '$normalizedBase/api/v1/public/mobile-config?tenantSlug=$slug';
    case ConfigMode.local:
      throw const RemoteConfigException(
        'resolveRemoteConfigUrl does not apply to local config mode.',
      );
  }
}
