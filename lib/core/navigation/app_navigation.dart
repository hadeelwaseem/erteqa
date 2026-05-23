import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// How a route transition affects the navigation stack.
enum NavigationType { push, clearStack }

/// Parses JSON / action `navigation_type` strings into [NavigationType].
NavigationType parseNavigationType(String? raw) {
  if (raw == null) {
    return NavigationType.clearStack;
  }
  final normalized = raw.trim().toLowerCase();
  if (normalized.isEmpty) {
    return NavigationType.clearStack;
  }
  switch (normalized) {
    case 'push':
    case 'stack':
      return NavigationType.push;
    case 'clear_stack':
    case 'clearstack':
    case 'reset':
    case 'go':
      return NavigationType.clearStack;
    default:
      return NavigationType.clearStack;
  }
}

/// Central GoRouter entry point for push vs clear-stack navigation.
class AppNavigation {
  AppNavigation._();

  /// Shell tab routes must use [NavigationType.clearStack] (`go`), not `push`.
  ///
  /// Pushing a tab route stacks a second page with the same GoRouter page key
  /// (e.g. `/cart`) and triggers Navigator duplicate-key assertions.
  static NavigationType resolveForRoute({
    required String route,
    required NavigationType requested,
    Set<String> tabRoutes = const {},
  }) {
    if (requested != NavigationType.push || tabRoutes.isEmpty) {
      return requested;
    }
    final path = _routePath(route);
    if (tabRoutes.contains(path)) {
      return NavigationType.clearStack;
    }
    return requested;
  }

  static String _routePath(String route) {
    final queryIndex = route.indexOf('?');
    final withoutQuery =
        queryIndex >= 0 ? route.substring(0, queryIndex) : route;
    final hashIndex = withoutQuery.indexOf('#');
    return hashIndex >= 0 ? withoutQuery.substring(0, hashIndex) : withoutQuery;
  }

  static void navigate(
    BuildContext context, {
    required String route,
    NavigationType type = NavigationType.clearStack,
    Set<String> tabRoutes = const {},
  }) {
    final effectiveType = resolveForRoute(
      route: route,
      requested: type,
      tabRoutes: tabRoutes,
    );
    switch (effectiveType) {
      case NavigationType.push:
        context.push(route);
      case NavigationType.clearStack:
        context.go(route);
    }
  }
}
