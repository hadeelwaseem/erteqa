import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
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
}
