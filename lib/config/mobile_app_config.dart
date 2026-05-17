import 'navigation_config.dart';

/// Top-level parsed model of the mobile JSON file.
///
/// Contains the app identity, navigation config, and all known page routes.
/// Pages are NOT pre-parsed here — they are loaded on demand by [VariantRepository].
///
/// Usage: load once at startup via [AppConfigLoader], pass into router setup.
class MobileAppConfig {
  /// The JSON file identifier (used as variantId when loading pages).
  final String variantId;

  final String schemaVersion;
  final String appName;
  final String bundleId;
  final String apiBaseUrl;
  final String? tenantId;
  final String? tenantSlug;
  final NavigationConfig navigation;

  /// All page routes defined in `pages[]`, e.g. ['/', '/products', '/product/1', '/checkout'].
  final List<String> pageRoutes;

  const MobileAppConfig({
    required this.variantId,
    required this.schemaVersion,
    required this.appName,
    required this.bundleId,
    required this.apiBaseUrl,
    this.tenantId,
    this.tenantSlug,
    required this.navigation,
    required this.pageRoutes,
  });

  factory MobileAppConfig.fromJson(
    Map<String, dynamic> json,
    String variantId,
  ) {
    final app = json['app'] as Map<String, dynamic>? ?? {};
    final navJson = json['navigation'] as Map<String, dynamic>? ?? {};
    final pages = (json['pages'] as List?)?.whereType<Map<String, dynamic>>() ?? [];
    final routes = pages
        .map((p) => p['route'] as String?)
        .whereType<String>()
        .where((r) => r.isNotEmpty)
        .toList();

    return MobileAppConfig(
      variantId: variantId,
      schemaVersion: json['schemaVersion'] as String? ?? '1.0',
      appName: app['name'] as String? ?? 'App',
      bundleId: app['bundleId'] as String? ?? '',
      apiBaseUrl: app['apiBaseUrl'] as String? ?? '',
      tenantId: app['tenantId'] as String?,
      tenantSlug: app['tenantSlug'] as String?,
      navigation: NavigationConfig.fromJson(navJson),
      pageRoutes: routes,
    );
  }

  /// Returns the page routes that are NOT represented by any tab.
  List<String> get nonTabRoutes {
    final tabRoutes = navigation.tabs.map((t) => t.route).toSet();
    return pageRoutes.where((r) => !tabRoutes.contains(r)).toList();
  }
}
