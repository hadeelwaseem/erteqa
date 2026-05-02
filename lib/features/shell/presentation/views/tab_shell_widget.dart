import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/navigation_config.dart';
import '../../../../../core/utils/icon_registry.dart';

/// Shell widget rendered by [ShellRoute].
///
/// Provides a top-level [Scaffold] with a [BottomNavigationBar] driven by
/// the JSON `navigation.tabs` array. Individual tab pages are rendered as
/// [child] by go_router.
///
/// Active tab is resolved by matching [state.matchedLocation] against
/// tab routes.
///
/// No hardcoded tabs — all content comes from [NavigationConfig].
class TabShellWidget extends StatelessWidget {
  const TabShellWidget({
    super.key,
    required this.navigationConfig,
    required this.currentLocation,
    required this.child,
  });

  final NavigationConfig navigationConfig;

  /// The currently matched location from go_router state.
  final String currentLocation;

  /// The active page widget from go_router (current route content).
  final Widget child;

  int _activeIndex() {
    final tabs = navigationConfig.tabs;
    // Exact match first
    for (var i = 0; i < tabs.length; i++) {
      if (tabs[i].route == currentLocation) return i;
    }
    // Prefix match (for sub-routes that still belong to a tab section)
    for (var i = 0; i < tabs.length; i++) {
      final tabRoute = tabs[i].route;
      if (tabRoute != '/' && currentLocation.startsWith(tabRoute)) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final tabs = navigationConfig.tabs;
    final activeIndex = _activeIndex();

    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: activeIndex,
        onTap: (index) {
          if (index < tabs.length) {
            context.go(tabs[index].route);
          }
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        items: tabs
            .map(
              (tab) => BottomNavigationBarItem(
                icon: Icon(IconRegistry.resolve(tab.icon)),
                label: tab.label,
              ),
            )
            .toList(),
      ),
    );
  }
}
