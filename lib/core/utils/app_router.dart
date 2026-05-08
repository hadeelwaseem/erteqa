import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:sooq_merchant/config/mobile_app_config.dart';
import 'package:sooq_merchant/core/utils/service_locator.dart';
import 'package:sooq_merchant/features/homescreen/presentation/views/home_screen.dart';
import 'package:sooq_merchant/features/shell/presentation/views/tab_shell_widget.dart';
import 'package:sooq_merchant/features/variantscreen/data/repos/variant_repository.dart';
import 'package:sooq_merchant/features/variantscreen/presentation/views/variant_screen.dart';

abstract class AppRouter {
  static const kMvp2View = '/mvp2';

  /// Builds the app router.
  ///
  /// When [mobileConfig] is provided (tab-shell mode):
  ///   - A [ShellRoute] wraps all JSON-defined pages with a [TabShellWidget]
  ///   - Tab routes (e.g. /, /products, /checkout) are first-class GoRoutes
  ///   - Non-tab routes (e.g. /product/1) are added as sub-routes in the shell
  ///
  /// When [mobileConfig] is null:
  ///   - Falls back to a simple direct VariantScreen (no shell / bottom bar)
  static GoRouter setupRouter(String? token, {MobileAppConfig? mobileConfig}) {
    final routes = <RouteBase>[];

    if (mobileConfig != null && mobileConfig.navigation.hasTabs) {
      // ── Tab shell mode ──────────────────────────────────────────────────────
      final variantId = mobileConfig.variantId;
      final tabs = mobileConfig.navigation.tabs;
      final shellExcludes = mobileConfig.navigation.shellExcludeRoutes.toSet();

      // Standalone routes (outside the shell)
      for (final route in mobileConfig.pageRoutes) {
        if (!shellExcludes.contains(route)) continue;
        routes.add(
          GoRoute(
            path: route,
            builder: (context, state) => VariantScreen(
              variantId: variantId,
              pageRoute: route,
              variantRepository: getIt<VariantRepository>(),
            ),
          ),
        );
      }

      // Build sub-routes for every page in the JSON
      final shellRoutes = <RouteBase>[];

      // 1. Tab routes
      for (final tab in tabs) {
        shellRoutes.add(
          GoRoute(
            path: tab.route,
            builder: (context, state) => VariantScreen(
              variantId: variantId,
              pageRoute: tab.route,
              variantRepository: getIt<VariantRepository>(),
            ),
          ),
        );
      }

      // 2. Non-tab page routes (e.g. /product/1)
      for (final route in mobileConfig.nonTabRoutes) {
        if (shellExcludes.contains(route)) continue;
        shellRoutes.add(
          GoRoute(
            path: route,
            builder: (context, state) => VariantScreen(
              variantId: variantId,
              pageRoute: route,
              variantRepository: getIt<VariantRepository>(),
            ),
          ),
        );
      }

      routes.add(
        ShellRoute(
          builder: (context, state, child) => TabShellWidget(
            navigationConfig: mobileConfig.navigation,
            currentLocation: state.matchedLocation,
            child: child,
          ),
          routes: shellRoutes,
        ),
      );
    } else {
      // ── Fallback: no mobileConfig, simple single-screen route ────────────
      routes.add(
        GoRoute(
          path: '/',
          builder: (context, state) => VariantScreen(
            variantId: 'mobile_component_flow_demo',
            variantRepository: getIt<VariantRepository>(),
          ),
        ),
      );
    }

    // ── Always-available diagnostic/legacy routes ─────────────────────────
    routes.add(
      GoRoute(
        path: kMvp2View,
        builder: (context, state) => const HomeScreen(),
      ),
    );

    // Legacy /variant/:id route (for direct deep-link / debug access)
    routes.add(
      GoRoute(
        path: '/variant/:id',
        builder: (context, state) {
          final pageId = state.pathParameters['id'] ?? 'mobile_component_flow_demo';
          final pageRoute = state.uri.queryParameters['route'];
          return VariantScreen(
            variantId: pageId,
            pageRoute: pageRoute,
            variantRepository: getIt<VariantRepository>(),
          );
        },
      ),
    );

    final router = GoRouter(
      routes: routes,
      debugLogDiagnostics: kDebugMode,
      initialLocation: mobileConfig?.navigation.initialRoute ?? '/',
    );

    return router;
  }
}
