import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sooq_merchant/config/component_config.dart';
import 'package:sooq_merchant/core/enums/generic_component_type.dart';
import 'package:sooq_merchant/engine/tree/renderers/stack_renderer.dart';

import 'renderer_test_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'stack expand uses Positioned.fill for fill layer and Align for overlay',
    (tester) async {
      final renderer = StackRenderer();
      final config = ComponentConfig(
        type: GenericComponentType.stack,
        properties: const {'fit': 'expand'},
        children: [
          const ComponentConfig(
            type: GenericComponentType.text,
            properties: {'value': 'bg', 'stackLayer': 'fill'},
          ),
          const ComponentConfig(
            type: GenericComponentType.text,
            properties: {
              'value': 'cta',
              'stackLayer': 'positioned',
              'stackAlign': 'bottomCenter',
            },
          ),
        ],
      );

      const rootKey = Key('stack-test-root');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              key: rootKey,
              height: 400,
              child: renderer.render(
                config,
                buildChild: (child) =>
                    Text(child.properties['value'] as String? ?? ''),
                dataContext: rendererDataContext(),
              ),
            ),
          ),
        ),
      );

      expect(
        find.descendant(of: find.byKey(rootKey), matching: find.byType(Stack)),
        findsOneWidget,
      );
      expect(find.byType(Positioned), findsWidgets);
      expect(find.byType(Align), findsOneWidget);
      expect(find.text('bg'), findsOneWidget);
      expect(find.text('cta'), findsOneWidget);
    },
  );

  testWidgets('stackInsetBottom pins overlay above screen bottom', (
    tester,
  ) async {
    final renderer = StackRenderer();
    final config = ComponentConfig(
      type: GenericComponentType.stack,
      properties: const {'fit': 'expand'},
      children: [
        const ComponentConfig(
          type: GenericComponentType.text,
          properties: {'value': 'bg', 'stackLayer': 'fill'},
        ),
        const ComponentConfig(
          type: GenericComponentType.text,
          properties: {
            'value': 'cta',
            'stackLayer': 'positioned',
            'stackInsetBottom': 72,
          },
        ),
      ],
    );

    const rootKey = Key('stack-inset-root');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            key: rootKey,
            height: 400,
            child: renderer.render(
              config,
              buildChild: (child) =>
                  Text(child.properties['value'] as String? ?? ''),
              dataContext: rendererDataContext(),
            ),
          ),
        ),
      ),
    );

    final positioned = tester.widgetList<Positioned>(
      find.descendant(
        of: find.byKey(rootKey),
        matching: find.byType(Positioned),
      ),
    );
    expect(
      positioned.any((p) => p.bottom == 72 && p.left == 0 && p.right == 0),
      isTrue,
    );
    expect(find.text('cta'), findsOneWidget);
  });
}
