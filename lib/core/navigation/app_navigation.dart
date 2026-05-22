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

  static void navigate(
    BuildContext context, {
    required String route,
    NavigationType type = NavigationType.clearStack,
  }) {
    switch (type) {
      case NavigationType.push:
        context.push(route);
      case NavigationType.clearStack:
        context.go(route);
    }
  }
}
