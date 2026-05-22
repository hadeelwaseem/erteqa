/// Navigation configuration parsed from the top-level JSON `navigation` block.
///
/// Drives the ShellRoute tab bar and routing structure.
class NavigationConfig {
  final String type;
  final String initialRoute;
  final List<TabConfig> tabs;
  final List<String> shellExcludeRoutes;

  /// Full-screen drill-down paths that reuse another page's JSON (`pages[].route`).
  ///
  /// Keys are registered routes (usually in [shellExcludeRoutes]); values are
  /// the canonical page route to load from `pages[]`.
  final Map<String, String> routeAliases;

  const NavigationConfig({
    required this.type,
    required this.initialRoute,
    required this.tabs,
    required this.shellExcludeRoutes,
    this.routeAliases = const {},
  });

  factory NavigationConfig.fromJson(Map<String, dynamic> json) {
    final tabList = (json['tabs'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .map(TabConfig.fromJson)
            .toList() ??
        [];
    final excludeRoutes = (json['shellExcludeRoutes'] as List?)
            ?.whereType<String>()
            .where((route) => route.isNotEmpty)
            .toList() ??
        [];
    final aliasesRaw = json['routeAliases'] as Map<String, dynamic>?;
    final routeAliases = <String, String>{};
    if (aliasesRaw != null) {
      for (final entry in aliasesRaw.entries) {
        final target = entry.value;
        if (entry.key.isNotEmpty &&
            target is String &&
            target.isNotEmpty) {
          routeAliases[entry.key] = target;
        }
      }
    }
    return NavigationConfig(
      type: json['type'] as String? ?? 'stack',
      initialRoute: json['initialRoute'] as String? ?? '/',
      tabs: tabList,
      shellExcludeRoutes: excludeRoutes,
      routeAliases: routeAliases,
    );
  }

  bool get hasTabs => type == 'tabs' && tabs.isNotEmpty;
}

/// A single tab definition from `navigation.tabs[]`.
class TabConfig {
  final String id;
  final String label;
  final String icon;
  final String route;

  const TabConfig({
    required this.id,
    required this.label,
    required this.icon,
    required this.route,
  });

  factory TabConfig.fromJson(Map<String, dynamic> json) {
    return TabConfig(
      id: json['id'] as String? ?? '',
      label: json['label'] as String? ?? '',
      icon: json['icon'] as String? ?? '',
      route: json['route'] as String? ?? '/',
    );
  }
}
