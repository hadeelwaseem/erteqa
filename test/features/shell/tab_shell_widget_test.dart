import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sooq_merchant/config/navigation_config.dart';
import 'package:sooq_merchant/features/shell/presentation/views/tab_shell_widget.dart';

NavigationConfig _testNavigationConfig() {
  return NavigationConfig.fromJson({
    'type': 'tabs',
    'initialRoute': '/home',
    'tabs': [
      {'id': 'tab-home', 'label': 'Home', 'icon': 'home', 'route': '/home'},
      {
        'id': 'tab-categories',
        'label': 'Categories',
        'icon': 'grid_view',
        'route': '/categories',
      },
    ],
    'shellExcludeRoutes': [],
  });
}

Widget _shellTestApp(GoRouter router) {
  return MaterialApp.router(routerConfig: router);
}

GoRouter _shellRouter({
  required List<RouteBase> shellChildRoutes,
  required GlobalKey<NavigatorState> shellNavigatorKey,
  String initialLocation = '/home',
}) {
  final nav = _testNavigationConfig();
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      ShellRoute(
        navigatorKey: shellNavigatorKey,
        builder: (context, state, child) => TabShellWidget(
          navigationConfig: nav,
          currentLocation: state.matchedLocation,
          shellStackCanPop: shellNavigatorKey.currentState?.canPop() ?? false,
          child: child,
        ),
        routes: shellChildRoutes,
      ),
    ],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('hides bottom bar on non-tab route inside shell', (tester) async {
    final shellNavigatorKey = GlobalKey<NavigatorState>();
    final router = _shellRouter(
      shellNavigatorKey: shellNavigatorKey,
      shellChildRoutes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => const Text('home'),
        ),
        GoRoute(
          path: '/products',
          builder: (context, state) => const Text('products'),
        ),
      ],
      initialLocation: '/products',
    );

    await tester.pumpWidget(_shellTestApp(router));
    await tester.pumpAndSettle();

    expect(find.byType(BottomNavigationBar), findsNothing);
    expect(find.text('products'), findsOneWidget);
  });

  testWidgets('shows bottom bar on tab root when stack cannot pop',
      (tester) async {
    final shellNavigatorKey = GlobalKey<NavigatorState>();
    final router = _shellRouter(
      shellNavigatorKey: shellNavigatorKey,
      shellChildRoutes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => const Text('home'),
        ),
        GoRoute(
          path: '/categories',
          builder: (context, state) => const Text('categories'),
        ),
      ],
      initialLocation: '/categories',
    );

    await tester.pumpWidget(_shellTestApp(router));
    await tester.pumpAndSettle();

    expect(find.byType(BottomNavigationBar), findsOneWidget);
    final bar = tester.widget<BottomNavigationBar>(
      find.byType(BottomNavigationBar),
    );
    expect(bar.currentIndex, 1);
  });

  testWidgets('hides bottom bar when shellStackCanPop is true on tab route',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: TabShellWidget(
          navigationConfig: _testNavigationConfig(),
          currentLocation: '/categories',
          shellStackCanPop: true,
          child: const Text('categories'),
        ),
      ),
    );

    expect(find.byType(BottomNavigationBar), findsNothing);
    expect(find.text('categories'), findsOneWidget);
  });
}
