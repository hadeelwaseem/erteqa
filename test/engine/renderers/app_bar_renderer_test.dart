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

    await tester.tap(find.byIcon(Icons.arrow_forward));
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

    expect(find.byIcon(Icons.arrow_forward), findsNothing);
    expect(find.text('Root'), findsOneWidget);
  });

  testWidgets('titleAlign start places title at directional start (RTL → right)',
      (tester) async {
    final renderer = AppBarRenderer();
    final config = ComponentConfig(
      type: GenericComponentType.appBar,
      properties: {'title': 'Start title'},
    );

    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => renderer.render(
            config,
            buildChild: (_) => const SizedBox.shrink(),
            dataContext: rendererDataContext(),
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.rtl,
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    final titleText = tester.widget<Text>(find.text('Start title'));
    expect(titleText.textAlign, TextAlign.start);

    final align = tester.widget<Align>(
      find.ancestor(of: find.text('Start title'), matching: find.byType(Align)),
    );
    expect(align.alignment, AlignmentDirectional.centerStart);
  });

  testWidgets('titleAlign center centers title text', (tester) async {
    final renderer = AppBarRenderer();
    final config = ComponentConfig(
      type: GenericComponentType.appBar,
      properties: {'title': 'Center title', 'titleAlign': 'center'},
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

    final titleText = tester.widget<Text>(find.text('Center title'));
    expect(titleText.textAlign, TextAlign.center);
  });

  testWidgets('height sets fixed app bar height', (tester) async {
    final renderer = AppBarRenderer();
    final config = ComponentConfig(
      type: GenericComponentType.appBar,
      properties: {'title': 'Tall bar', 'height': 72},
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

    expect(
      tester.widgetList<SizedBox>(
        find.descendant(
          of: find.byType(Material),
          matching: find.byWidgetPredicate(
            (w) => w is SizedBox && w.height == 72,
          ),
        ),
      ),
      hasLength(1),
    );
  });

  testWidgets('elevation defaults to 1', (tester) async {
    final renderer = AppBarRenderer();
    final config = ComponentConfig(
      type: GenericComponentType.appBar,
      properties: {'title': 'Default elevation'},
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

    final appBarMaterial = tester
        .widgetList<Material>(find.byType(Material))
        .firstWhere((material) => material.elevation == 1);
    expect(appBarMaterial.elevation, 1);
  });

  testWidgets('elevation 0 uses transparent Material styling', (tester) async {
    final renderer = AppBarRenderer();
    final config = ComponentConfig(
      type: GenericComponentType.appBar,
      properties: {
        'title': 'Flat bar',
        'backgroundColor': '#00000000',
        'elevation': 0,
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

    final appBarMaterial = tester.widgetList<Material>(find.byType(Material)).firstWhere(
      (material) =>
          material.elevation == 0 && material.color == Colors.transparent,
    );
    expect(appBarMaterial.elevation, 0);
    expect(appBarMaterial.color, Colors.transparent);
    expect(appBarMaterial.shadowColor, Colors.transparent);
  });

  testWidgets('applies status bar top padding for edge-to-edge layout',
      (tester) async {
    final renderer = AppBarRenderer();
    final config = ComponentConfig(
      type: GenericComponentType.appBar,
      properties: {'title': 'Status bar inset'},
    );

    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => MediaQuery(
            data: const MediaQueryData(padding: EdgeInsets.only(top: 44)),
            child: renderer.render(
              config,
              buildChild: (_) => const SizedBox.shrink(),
              dataContext: rendererDataContext(),
            ),
          ),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));

    expect(
      find.descendant(
        of: find.byType(Material),
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is Padding &&
              widget.padding == const EdgeInsets.only(top: 44),
        ),
      ),
      findsOneWidget,
    );
  });
}
