import 'bootstrap_config.dart';
import 'models/mobile_theme_config.dart';
import 'navigation_config.dart';

/// Top-level parsed model combining bootstrap identity + render UI JSON.
///
/// **Identity** (`appName`, `bundleId`, `apiBaseUrl`, tenant) comes from
/// [BootstrapConfig]. **UI** (`theme`, `navigation`, `pages`) comes from render JSON.
///
/// Pages are NOT pre-parsed here — loaded on demand by [VariantRepository].
class MobileAppConfig {
  /// The JSON file identifier (used as variantId when loading pages).
  final String variantId;

  final String schemaVersion;
  final String appName;
  final String bundleId;
  final String apiBaseUrl;
  final String? tenantId;
  final String? tenantSlug;
  final String? supportWhatsApp;
  final String? supportPhone;
  final NavigationConfig navigation;
  final MobileThemeConfig theme;

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
    this.supportWhatsApp,
    this.supportPhone,
    required this.navigation,
    required this.theme,
    required this.pageRoutes,
  });

  factory MobileAppConfig.fromBootstrapAndRender({
    required BootstrapConfig bootstrap,
    required Map<String, dynamic> renderJson,
  }) {
    final navJson = renderJson['navigation'] as Map<String, dynamic>? ?? {};
    final pages =
        (renderJson['pages'] as List?)?.whereType<Map<String, dynamic>>() ??
        [];
    final navigation = NavigationConfig.fromJson(navJson);
    final routes = pages
        .map((p) => p['route'] as String?)
        .whereType<String>()
        .where((r) => r.isNotEmpty)
        .toList();
    for (final aliasRoute in navigation.routeAliases.keys) {
      if (!routes.contains(aliasRoute)) {
        routes.add(aliasRoute);
      }
    }

    return MobileAppConfig(
      variantId: bootstrap.variantId,
      schemaVersion: renderJson['schemaVersion'] as String? ?? '1.0',
      appName: bootstrap.appName,
      bundleId: bootstrap.bundleId,
      apiBaseUrl: bootstrap.apiBaseUrl,
      tenantId: bootstrap.tenantId,
      tenantSlug: bootstrap.tenantSlug,
      supportWhatsApp: null,
      supportPhone: null,
      navigation: navigation,
      theme: MobileThemeConfig.fromJson(
        renderJson['theme'] as Map<String, dynamic>?,
      ),
      pageRoutes: routes,
    );
  }

  /// Monolithic legacy JSON with optional `app` block (tests/tooling only).
  ///
  /// **Deprecated:** Use [fromBootstrapAndRender]. When [bootstrap] is passed,
  /// any `json['app']` block is ignored.
  @Deprecated('Use MobileAppConfig.fromBootstrapAndRender')
  factory MobileAppConfig.fromJson(
    Map<String, dynamic> json,
    String variantId, {
    BootstrapConfig? bootstrap,
  }) {
    if (bootstrap != null) {
      return MobileAppConfig.fromBootstrapAndRender(
        bootstrap: bootstrap,
        renderJson: json,
      );
    }

    final app = json['app'] as Map<String, dynamic>? ?? {};
    final navJson = json['navigation'] as Map<String, dynamic>? ?? {};
    final pages = (json['pages'] as List?)?.whereType<Map<String, dynamic>>() ?? [];
    final navigation = NavigationConfig.fromJson(navJson);
    final routes = pages
        .map((p) => p['route'] as String?)
        .whereType<String>()
        .where((r) => r.isNotEmpty)
        .toList();
    for (final aliasRoute in navigation.routeAliases.keys) {
      if (!routes.contains(aliasRoute)) {
        routes.add(aliasRoute);
      }
    }

    return MobileAppConfig(
      variantId: variantId,
      schemaVersion: json['schemaVersion'] as String? ?? '1.0',
      appName: app['name'] as String? ?? 'App',
      bundleId: app['bundleId'] as String? ?? '',
      apiBaseUrl: app['apiBaseUrl'] as String? ?? '',
      tenantId: app['tenantId'] as String?,
      tenantSlug: app['tenantSlug'] as String?,
      supportWhatsApp: app['supportWhatsApp'] as String?,
      supportPhone: app['supportPhone'] as String?,
      navigation: navigation,
      theme: MobileThemeConfig.fromJson(
        json['theme'] as Map<String, dynamic>?,
      ),
      pageRoutes: routes,
    );
  }

  /// Returns the page routes that are NOT represented by any tab.
  List<String> get nonTabRoutes {
    final tabRoutes = navigation.tabs.map((t) => t.route).toSet();
    return pageRoutes.where((r) => !tabRoutes.contains(r)).toList();
  }
}
