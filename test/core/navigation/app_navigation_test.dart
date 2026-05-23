import 'package:flutter_test/flutter_test.dart';
import 'package:sooq_merchant/core/navigation/app_navigation.dart';

void main() {
  group('AppNavigation.resolveForRoute', () {
    const tabRoutes = {'/home', '/cart', '/profile'};

    test('keeps push for non-tab routes', () {
      expect(
        AppNavigation.resolveForRoute(
          route: '/product/details/foo',
          requested: NavigationType.push,
          tabRoutes: tabRoutes,
        ),
        NavigationType.push,
      );
    });

    test('downgrades push to clearStack for tab routes', () {
      expect(
        AppNavigation.resolveForRoute(
          route: '/cart',
          requested: NavigationType.push,
          tabRoutes: tabRoutes,
        ),
        NavigationType.clearStack,
      );
    });

    test('ignores query on tab route path', () {
      expect(
        AppNavigation.resolveForRoute(
          route: '/cart?ref=pdp',
          requested: NavigationType.push,
          tabRoutes: tabRoutes,
        ),
        NavigationType.clearStack,
      );
    });

    test('leaves clearStack unchanged for tab routes', () {
      expect(
        AppNavigation.resolveForRoute(
          route: '/cart',
          requested: NavigationType.clearStack,
          tabRoutes: tabRoutes,
        ),
        NavigationType.clearStack,
      );
    });
  });
}
