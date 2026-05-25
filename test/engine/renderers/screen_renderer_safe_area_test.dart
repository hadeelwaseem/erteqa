import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sooq_merchant/config/component_config.dart';
import 'package:sooq_merchant/config/screen_config.dart';
import 'package:sooq_merchant/core/enums/generic_component_type.dart';
import 'package:sooq_merchant/engine/screen_renderer/screen_renderer.dart';

import 'renderer_test_utils.dart';

ScreenConfig _pageWithAppBar() {
  return ScreenConfig(
    pageId: 'safe-area-root',
    pageName: 'Safe Area Root',
    root: ComponentConfig(
      type: GenericComponentType.scaffold,
      properties: const {'pageScroll': 'none'},
      child: ComponentConfig(
        type: GenericComponentType.column,
        properties: const {
          'safeAreaBody': true,
          'mainAxisSize': 'max',
          'crossAxisAlignment': 'stretch',
        },
        children: [
          ComponentConfig(
            type: GenericComponentType.appBar,
            properties: const {'title': 'Bar'},
          ),
          ComponentConfig(
            type: GenericComponentType.text,
            properties: const {'value': 'Body content'},
          ),
        ],
      ),
    ),
  );
}

ScreenConfig _pageWithoutAppBar() {
  return ScreenConfig(
    pageId: 'safe-area-no-appbar',
    pageName: 'Safe Area No AppBar',
    root: ComponentConfig(
      type: GenericComponentType.scaffold,
      child: ComponentConfig(
        type: GenericComponentType.column,
        properties: const {
          'safeAreaBody': true,
          'crossAxisAlignment': 'stretch',
        },
        children: [
          ComponentConfig(
            type: GenericComponentType.text,
            properties: const {'value': 'Only body'},
          ),
        ],
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('ScreenRenderer does not wrap full page in SafeArea', (tester) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => ScreenRenderer.withPrimitives().render(
            _pageWithAppBar(),
            context: context,
            dataContext: rendererDataContext(),
          ),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));

    expect(find.byType(SafeArea), findsOneWidget);
    final safeArea = tester.widget<SafeArea>(find.byType(SafeArea));
    expect(safeArea.top, isFalse);
    expect(find.text('Body content'), findsOneWidget);
    expect(find.text('Bar'), findsOneWidget);
  });

  testWidgets('safeAreaBody without appBar wraps entire column in SafeArea',
      (tester) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => ScreenRenderer.withPrimitives().render(
            _pageWithoutAppBar(),
            context: context,
            dataContext: rendererDataContext(),
          ),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));

    expect(find.byType(SafeArea), findsOneWidget);
    final safeArea = tester.widget<SafeArea>(find.byType(SafeArea));
    expect(safeArea.top, isTrue);
    expect(find.text('Only body'), findsOneWidget);
  });
}
