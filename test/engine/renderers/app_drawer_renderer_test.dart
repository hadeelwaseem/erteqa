import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sooq_merchant/config/component_config.dart';
import 'package:sooq_merchant/core/enums/generic_component_type.dart';
import 'package:sooq_merchant/engine/actions/action_dispatcher.dart';
import 'package:sooq_merchant/engine/engine_page_chrome.dart';
import 'package:sooq_merchant/engine/screen_renderer/screen_renderer.dart';
import 'package:sooq_merchant/config/screen_config.dart';
import 'package:sooq_merchant/engine/tree/renderers/app_drawer_renderer.dart';
import 'package:sooq_merchant/engine/tree/renderers/text_renderer.dart';

import 'renderer_test_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('appDrawer registers drawer in dataContext', (tester) async {
    final dataContext = rendererDataContext()
      ..[EnginePageChromeRegistry.contextKey] = EnginePageChromeRegistry();
    final renderer = AppDrawerRenderer();
    final config = ComponentConfig(
      type: GenericComponentType.appDrawer,
      properties: const {
        'width': 300,
        'backgroundColor': '#FF0000',
        'drawerEdge': 'start',
      },
      child: ComponentConfig(
        type: GenericComponentType.text,
        properties: {'value': 'Menu'},
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            renderer.render(
              config,
              buildChild: (child) => TextRenderer().render(
                child,
                buildChild: (_) => const SizedBox.shrink(),
                dataContext: dataContext,
              ),
              dataContext: dataContext,
            );
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    final registry =
        dataContext[EnginePageChromeRegistry.contextKey]!
            as EnginePageChromeRegistry;
    expect(registry.drawer, isA<Drawer>());
    final drawerWidget = registry.drawer! as Drawer;
    expect(drawerWidget.width, 300);
    expect(drawerWidget.backgroundColor, const Color(0xFFFF0000));
    expect(drawerWidget.child, isA<SafeArea>());
    expect(registry.drawerEdge, 'start');
  });

  testWidgets('appDrawer SafeArea insets content below status bar', (
    tester,
  ) async {
    const statusBarHeight = 44.0;
    final dataContext = rendererDataContext()
      ..[EnginePageChromeRegistry.contextKey] = EnginePageChromeRegistry();
    final renderer = AppDrawerRenderer();
    final config = ComponentConfig(
      type: GenericComponentType.appDrawer,
      properties: const {'width': 280},
      child: ComponentConfig(
        type: GenericComponentType.text,
        properties: {'value': 'Menu'},
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(padding: EdgeInsets.only(top: statusBarHeight)),
          child: Builder(
            builder: (context) {
              renderer.render(
                config,
                buildChild: (child) => TextRenderer().render(
                  child,
                  buildChild: (_) => const SizedBox.shrink(),
                  dataContext: dataContext,
                ),
                dataContext: dataContext,
              );
              final registry =
                  dataContext[EnginePageChromeRegistry.contextKey]!
                      as EnginePageChromeRegistry;
              return registry.drawer ?? const SizedBox.shrink();
            },
          ),
        ),
      ),
    );

    final menuOffset = tester.getTopLeft(find.text('Menu'));
    expect(menuOffset.dy, greaterThanOrEqualTo(statusBarHeight));
  });

  testWidgets('ScreenRenderer wraps page with inner Scaffold drawer', (
    tester,
  ) async {
    final screen = ScreenConfig(
      pageId: 'test',
      pageName: 'test',
      root: ComponentConfig(
        type: GenericComponentType.scaffold,
        properties: const {'pageScroll': 'none'},
        child: ComponentConfig(
          type: GenericComponentType.column,
          children: [
            ComponentConfig(
              type: GenericComponentType.appDrawer,
              properties: const {'drawerEdge': 'end'},
              child: ComponentConfig(
                type: GenericComponentType.text,
                properties: {'value': 'Drawer item'},
              ),
            ),
            ComponentConfig(
              type: GenericComponentType.text,
              properties: {'value': 'Body'},
            ),
          ],
        ),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => ScreenRenderer.withPrimitives().render(
            screen,
            context: context,
            dataContext: rendererDataContext(),
          ),
        ),
      ),
    );

    expect(find.byType(Scaffold), findsOneWidget);
    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.endDrawer, isNotNull);
    expect(scaffold.drawer, isNull);
    expect(find.text('Body'), findsOneWidget);
  });

  testWidgets('openDrawer uses page scaffold key not outer shell', (
    tester,
  ) async {
    final dataContext = rendererDataContext();
    final registry = EnginePageChromeRegistry();
    dataContext[EnginePageChromeRegistry.contextKey] = registry;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return Scaffold(
                key: registry.scaffoldKey,
                drawer: const Drawer(child: Text('Side menu')),
                body: ElevatedButton(
                  onPressed: () {
                    EngineActionDispatcher(
                      context: context,
                      dataContext: dataContext,
                    ).dispatch({'type': 'openDrawer'});
                  },
                  child: const Text('Open'),
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Side menu'), findsOneWidget);
  });
}
