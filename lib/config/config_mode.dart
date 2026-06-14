/// How the app loads its full runtime UI config at startup.
enum ConfigMode {
  /// Bundled asset: `assets/config/{variantId}.json`.
  local,

  /// HTTP GET from [BootstrapConfig.configUrl] (object storage CDN).
  remoteStorage,

  /// HTTP GET from `{apiBaseUrl}/api/v1/public/mobile-config?tenantSlug=...`.
  remoteApi;

  static ConfigMode fromJson(String? value) {
    switch (value?.trim()) {
      case 'remoteStorage':
        return ConfigMode.remoteStorage;
      case 'remoteApi':
        return ConfigMode.remoteApi;
      case 'local':
      default:
        return ConfigMode.local;
    }
  }

  String toJson() {
    switch (this) {
      case ConfigMode.local:
        return 'local';
      case ConfigMode.remoteStorage:
        return 'remoteStorage';
      case ConfigMode.remoteApi:
        return 'remoteApi';
    }
  }
}
