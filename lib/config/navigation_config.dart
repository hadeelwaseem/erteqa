/// Navigation configuration parsed from the top-level JSON `navigation` block.
///
/// Drives the ShellRoute tab bar and routing structure.
class NavigationConfig {
  final String type;
  final String initialRoute;
  final List<TabConfig> tabs;
  final List<String> shellExcludeRoutes;

  const NavigationConfig({
    required this.type,
    required this.initialRoute,
    required this.tabs,
    required this.shellExcludeRoutes,
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
    return NavigationConfig(
      type: json['type'] as String? ?? 'stack',
      initialRoute: json['initialRoute'] as String? ?? '/',
      tabs: tabList,
      shellExcludeRoutes: excludeRoutes,
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
