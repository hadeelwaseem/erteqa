import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:sooq_merchant/config/mobile_app_config.dart';
import 'package:sooq_merchant/core/cubits/token_cubit/token_cubit.dart';
import 'package:sooq_merchant/core/navigation/auth_redirect.dart';
import 'package:sooq_merchant/core/navigation/token_refresh_listenable.dart';
import 'package:sooq_merchant/core/utils/service_locator.dart';
import 'package:sooq_merchant/features/homescreen/presentation/views/home_screen.dart';
import 'package:sooq_merchant/features/shell/presentation/views/tab_shell_widget.dart';
import 'package:sooq_merchant/features/variantscreen/data/repos/variant_repository.dart';
import 'package:sooq_merchant/features/variantscreen/presentation/views/variant_screen.dart';

abstract class AppRouter {
  static const kMvp2View = '/mvp2';

  /// Builds the app router with auth-aware redirects and session restore.
  static GoRouter setupRouter({
    required TokenCubit tokenCubit,
    MobileAppConfig? mobileConfig,
  }) {
    final routes = <RouteBase>[];
    final refreshListenable = TokenRefreshListenable(tokenCubit);

    if (mobileConfig != null && mobileConfig.navigation.hasTabs) {
      final variantId = mobileConfig.variantId;
      final tabs = mobileConfig.navigation.tabs;
      final shellExcludes = mobileConfig.navigation.shellExcludeRoutes.toSet();

      for (final route in mobileConfig.pageRoutes) {
        if (!shellExcludes.contains(route)) continue;
        routes.add(
          GoRoute(
            path: route,
            builder: (context, state) => _buildVariantScreen(
              variantId: variantId,
              pageRoute: route,
              routeParams: state.pathParameters,
              queryParams: state.uri.queryParameters,
            ),
          ),
        );
      }

      final shellRoutes = <RouteBase>[];

      for (final tab in tabs) {
        shellRoutes.add(
          GoRoute(
            path: tab.route,
            builder: (context, state) => _buildVariantScreen(
              variantId: variantId,
              pageRoute: tab.route,
              routeParams: state.pathParameters,
              queryParams: state.uri.queryParameters,
            ),
          ),
        );
      }

      for (final route in mobileConfig.nonTabRoutes) {
        if (shellExcludes.contains(route)) continue;
        shellRoutes.add(
          GoRoute(
            path: route,
            builder: (context, state) => _buildVariantScreen(
              variantId: variantId,
              pageRoute: route,
              routeParams: state.pathParameters,
              queryParams: state.uri.queryParameters,
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
      routes.add(
        GoRoute(
          path: '/',
          builder: (context, state) => _buildVariantScreen(
            variantId: 'mobile_component_flow_demo',
          ),
        ),
      );
    }

    routes.add(
      GoRoute(
        path: kMvp2View,
        builder: (context, state) => const HomeScreen(),
      ),
    );

    routes.add(
      GoRoute(
        path: '/variant/:id',
        builder: (context, state) {
          final pageId = state.pathParameters['id'] ?? 'mobile_component_flow_demo';
          final pageRoute = state.uri.queryParameters['route'];
          return _buildVariantScreen(
            variantId: pageId,
            pageRoute: pageRoute,
            routeParams: state.pathParameters,
            queryParams: state.uri.queryParameters,
          );
        },
      ),
    );

    return GoRouter(
      routes: routes,
      debugLogDiagnostics: kDebugMode,
      refreshListenable: refreshListenable,
      initialLocation: AuthRedirect.initialLocation(
        token: tokenCubit.state,
        mobileConfig: mobileConfig,
      ),
      redirect: (context, state) {
        return AuthRedirect.resolve(
          token: tokenCubit.state,
          matchedLocation: state.matchedLocation,
        );
      },
    );
  }

  static Widget _buildVariantScreen({
    required String variantId,
    String? pageRoute,
    Map<String, String> routeParams = const {},
    Map<String, String> queryParams = const {},
  }) {
    return VariantScreen(
      variantId: variantId,
      pageRoute: pageRoute,
      routeParams: routeParams,
      queryParams: queryParams,
      variantRepository: getIt<VariantRepository>(),
      mobileAppConfig: registeredMobileAppConfig,
    );
  }
}
