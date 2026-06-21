import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:sooq_merchant/core/cubits/token_cubit/token_cubit.dart';
import 'package:sooq_merchant/core/navigation/auth_redirect.dart';
import 'package:sooq_merchant/core/network/auth_token_storage.dart';
import 'package:sooq_merchant/engine/actions/action_dispatcher.dart';

class _MemoryTokenStorage implements AuthTokenStorage {
  String? _accessToken;

  @override
  Future<void> clearTokens() async {
    _accessToken = null;
  }

  @override
  Future<String?> readAccessToken() async => _accessToken;

  @override
  Future<String?> readRefreshToken() async => _accessToken;

  @override
  Future<DateTime?> readExpiresAt() async => null;

  @override
  Future<String?> readTenantId() async => null;

  @override
  Future<AuthTokenBundle> readTokenBundle() async => AuthTokenBundle(
        accessToken: _accessToken,
        refreshToken: _accessToken,
      );

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    DateTime? expiresAt,
    String? tenantId,
  }) async {
    _accessToken = accessToken;
  }
}

void main() {
  final locator = GetIt.instance;
  late TokenCubit tokenCubit;

  setUp(() {
    if (locator.isRegistered<TokenCubit>()) {
      locator.unregister<TokenCubit>();
    }
    tokenCubit = TokenCubit(_MemoryTokenStorage());
    locator.registerLazySingleton<TokenCubit>(() => tokenCubit);
  });

  tearDown(() {
    if (locator.isRegistered<TokenCubit>()) {
      locator.unregister<TokenCubit>();
    }
  });

  testWidgets('requireAuth without token shows auth sheet not hard redirect', (
    tester,
  ) async {
    late GoRouter router;

    router = GoRouter(
      initialLocation: '/start',
      routes: [
        GoRoute(
          path: '/start',
          builder: (context, state) {
            final dispatcher = EngineActionDispatcher(context: context);
            return Scaffold(
              body: ElevatedButton(
                onPressed: () => dispatcher.dispatch({
                  'type': 'navigate',
                  'route': '/orders',
                  'requireAuth': true,
                }),
                child: const Text('Protected'),
              ),
            );
          },
        ),
        GoRoute(
          path: '/orders',
          builder: (context, state) => const Scaffold(body: Text('Orders')),
        ),
        GoRoute(
          path: AuthRedirect.loginRoute,
          builder: (context, state) => const Scaffold(body: Text('Login')),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.tap(find.text('Protected'));
    await tester.pumpAndSettle();

    expect(router.state.uri.path, '/start');
    expect(find.text('تسجيل الدخول مطلوب'), findsOneWidget);
    expect(find.text('Orders'), findsNothing);
    expect(find.text('Login'), findsNothing);
  });

  testWidgets('requireAuth with token allows navigation', (tester) async {
    late GoRouter router;

    await tokenCubit.storeToken('access-token');

    router = GoRouter(
      initialLocation: '/start',
      routes: [
        GoRoute(
          path: '/start',
          builder: (context, state) {
            final dispatcher = EngineActionDispatcher(context: context);
            return Scaffold(
              body: ElevatedButton(
                onPressed: () => dispatcher.dispatch({
                  'type': 'navigate',
                  'route': '/orders',
                  'navigation_type': 'push',
                  'requireAuth': true,
                }),
                child: const Text('Protected'),
              ),
            );
          },
        ),
        GoRoute(
          path: '/orders',
          builder: (context, state) => const Scaffold(body: Text('Orders')),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.tap(find.text('Protected'));
    await tester.pumpAndSettle();

    expect(router.state.uri.path, '/orders');
    expect(find.text('Orders'), findsOneWidget);
  });

  testWidgets('onUnauthenticated override runs instead of auth sheet', (
    tester,
  ) async {
    late GoRouter router;
    var overrideRan = false;

    router = GoRouter(
      initialLocation: '/start',
      routes: [
        GoRoute(
          path: '/start',
          builder: (context, state) {
            final dispatcher = EngineActionDispatcher(context: context);
            return Scaffold(
              body: ElevatedButton(
                onPressed: () => dispatcher.dispatch({
                  'type': 'navigate',
                  'route': '/orders',
                  'requireAuth': true,
                  'onUnauthenticated': {
                    'type': 'navigate',
                    'route': '/custom',
                  },
                }),
                child: const Text('Protected'),
              ),
            );
          },
        ),
        GoRoute(
          path: '/orders',
          builder: (context, state) => const Scaffold(body: Text('Orders')),
        ),
        GoRoute(
          path: '/custom',
          builder: (context, state) {
            overrideRan = true;
            return const Scaffold(body: Text('Custom'));
          },
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.tap(find.text('Protected'));
    await tester.pumpAndSettle();

    expect(overrideRan, isTrue);
    expect(router.state.uri.path, '/custom');
    expect(find.text('تسجيل الدخول مطلوب'), findsNothing);
  });
}
