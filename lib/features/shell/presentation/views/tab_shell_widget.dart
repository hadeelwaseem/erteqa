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
    this.shellStackCanPop = false,
  });

  final NavigationConfig navigationConfig;

  /// The currently matched location from go_router state.
  final String currentLocation;

  /// Whether the [ShellRoute] nested navigator has more than one page.
  ///
  /// Passed from [ShellRoute.navigatorKey] in [AppRouter] — not
  /// [GoRouter.canPop], which does not reflect the shell stack.
  final bool shellStackCanPop;

  /// The active page widget from go_router (current route content).
  final Widget child;

  /// Index of the tab whose route exactly matches [currentLocation], or -1.
  int _tabIndexForLocation() {
    final tabs = navigationConfig.tabs;
    for (var i = 0; i < tabs.length; i++) {
      if (tabs[i].route == currentLocation) return i;
    }
    return -1;
  }

  /// Bottom bar only on tab roots (exact tab route, not a stacked drill-down).
  bool _shouldShowBottomNav() {
    if (_tabIndexForLocation() < 0) return false;
    return !shellStackCanPop;
  }

  @override
  Widget build(BuildContext context) {
    final tabs = navigationConfig.tabs;
    final tabIndex = _tabIndexForLocation();
    final showBottomNav = _shouldShowBottomNav();
    final activeIndex = tabIndex >= 0 ? tabIndex : 0;

    return Scaffold(
      body: child,
      bottomNavigationBar: showBottomNav
          ? BottomNavigationBar(
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
            )
          : null,
    );
  }
}
