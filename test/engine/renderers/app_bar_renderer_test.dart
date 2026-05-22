import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sooq_merchant/config/component_config.dart';
import 'package:sooq_merchant/core/enums/generic_component_type.dart';
import 'package:sooq_merchant/engine/tree/renderers/app_bar_renderer.dart';

import 'renderer_test_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('foregroundColor applies to title text', (tester) async {
    final renderer = AppBarRenderer();
    final config = ComponentConfig(
      type: GenericComponentType.appBar,
      properties: {
        'title': 'Test',
        'backgroundColor': '#FFFFFF',
        'foregroundColor': '#FF0000',
      },
    );

    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Scaffold(
            body: renderer.render(
              config,
              buildChild: (_) => const SizedBox.shrink(),
              dataContext: rendererDataContext(),
            ),
          ),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));

    final titleText = tester.widget<Text>(find.text('Test'));
    expect(titleText.style?.color, const Color(0xFFFF0000));
  });

  testWidgets('back IconButton has minimum 48x48 tap target when can pop',
      (tester) async {
    final renderer = AppBarRenderer();
    final config = ComponentConfig(
      type: GenericComponentType.appBar,
      properties: {'title': 'Back test'},
    );

    late GoRouter router;

    router = GoRouter(
      initialLocation: '/start',
      routes: [
        GoRoute(
          path: '/start',
          builder: (context, state) => Scaffold(
            body: ElevatedButton(
              onPressed: () => context.push('/detail'),
              child: const Text('push'),
            ),
          ),
        ),
        GoRoute(
          path: '/detail',
          builder: (context, state) => Scaffold(
            body: renderer.render(
              config,
              buildChild: (_) => const SizedBox.shrink(),
              dataContext: rendererDataContext(),
            ),
          ),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.tap(find.text('push'));
    await tester.pumpAndSettle();

    final iconButton = tester.widget<IconButton>(find.byType(IconButton));
    expect(iconButton.constraints?.minWidth, 48);
    expect(iconButton.constraints?.minHeight, 48);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    expect(router.state.uri.path, '/start');
    expect(find.text('push'), findsOneWidget);
  });

  testWidgets('back IconButton hidden when GoRouter cannot pop', (tester) async {
    final renderer = AppBarRenderer();
    final config = ComponentConfig(
      type: GenericComponentType.appBar,
      properties: {'title': 'Root'},
    );

    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Scaffold(
            body: renderer.render(
              config,
              buildChild: (_) => const SizedBox.shrink(),
              dataContext: rendererDataContext(),
            ),
          ),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));

    expect(find.byIcon(Icons.arrow_back), findsNothing);
    expect(find.text('Root'), findsOneWidget);
  });
}
