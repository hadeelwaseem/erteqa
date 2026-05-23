import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:sooq_merchant/core/cubits/token_cubit/token_cubit.dart';
import 'package:sooq_merchant/core/navigation/auth_redirect.dart';
import 'package:sooq_merchant/core/network/auth_token_storage.dart';
import 'package:sooq_merchant/engine/actions/action_dispatcher.dart';

void main() {
  testWidgets('navigate without navigation_type uses go (clear stack)', (tester) async {
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
                  'route': '/home',
                }),
                child: const Text('GoHome'),
              ),
            );
          },
        ),
        GoRoute(
          path: '/home',
          builder: (context, state) => const Scaffold(body: Text('Home')),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.tap(find.text('GoHome'));
    await tester.pumpAndSettle();

    expect(router.state.uri.path, '/home');
    expect(router.canPop(), isFalse);
  });

  testWidgets('navigate with clear_stack uses go', (tester) async {
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
                  'route': '/home',
                  'navigation_type': 'clear_stack',
                }),
                child: const Text('GoHome'),
              ),
            );
          },
        ),
        GoRoute(
          path: '/home',
          builder: (context, state) => const Scaffold(body: Text('Home')),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.tap(find.text('GoHome'));
    await tester.pumpAndSettle();

    expect(router.state.uri.path, '/home');
    expect(router.canPop(), isFalse);
  });

  testWidgets('navigate with push keeps stack', (tester) async {
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
                  'route': '/detail',
                  'navigation_type': 'push',
                }),
                child: const Text('PushDetail'),
              ),
            );
          },
        ),
        GoRoute(
          path: '/detail',
          builder: (context, state) => const Scaffold(body: Text('Detail')),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.tap(find.text('PushDetail'));
    await tester.pumpAndSettle();

    expect(router.state.uri.path, '/detail');
    expect(router.canPop(), isTrue);
  });

  testWidgets('navigate with stack alias uses push', (tester) async {
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
                  'route': '/detail',
                  'navigation_type': 'stack',
                }),
                child: const Text('PushDetail'),
              ),
            );
          },
        ),
        GoRoute(
          path: '/detail',
          builder: (context, state) => const Scaffold(body: Text('Detail')),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.tap(find.text('PushDetail'));
    await tester.pumpAndSettle();

    expect(router.state.uri.path, '/detail');
    expect(router.canPop(), isTrue);
  });

  testWidgets('authenticated navigate to splash-carousel goes home', (tester) async {
    final getIt = GetIt.instance;
    if (getIt.isRegistered<TokenCubit>()) {
      await getIt.unregister<TokenCubit>();
    }
    final storage = _MemoryTokenStorage()..seedToken('session-token');
    final tokenCubit = TokenCubit(storage);
    await tokenCubit.fetchSavedToken();
    getIt.registerSingleton<TokenCubit>(tokenCubit);
    addTearDown(() async {
      if (getIt.isRegistered<TokenCubit>()) {
        await getIt.unregister<TokenCubit>();
      }
    });

    late GoRouter router;

    router = GoRouter(
      initialLocation: AuthRedirect.splashRoute,
      redirect: (context, state) => AuthRedirect.resolve(
        token: tokenCubit.state,
        matchedLocation: state.matchedLocation,
      ),
      routes: [
        GoRoute(
          path: AuthRedirect.splashRoute,
          builder: (context, state) {
            final dispatcher = EngineActionDispatcher(context: context);
            return Scaffold(
              body: ElevatedButton(
                onPressed: () => dispatcher.dispatch({
                  'type': 'navigate',
                  'route': AuthRedirect.splashCarouselRoute,
                  'navigation_type': 'clear_stack',
                }),
                child: const Text('TimerNav'),
              ),
            );
          },
        ),
        GoRoute(
          path: AuthRedirect.homeRoute,
          builder: (context, state) => const Scaffold(body: Text('Home')),
        ),
        GoRoute(
          path: AuthRedirect.splashCarouselRoute,
          builder: (context, state) =>
              const Scaffold(body: Text('Carousel')),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.tap(find.text('TimerNav'));
    await tester.pumpAndSettle();

    expect(router.state.uri.path, AuthRedirect.homeRoute);
    expect(find.text('Home'), findsOneWidget);
  });
}

class _MemoryTokenStorage implements AuthTokenStorage {
  String? _accessToken;

  void seedToken(String token) => _accessToken = token;

  @override
  Future<void> clearTokens() async => _accessToken = null;

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
