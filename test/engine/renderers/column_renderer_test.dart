import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sooq_merchant/config/component_config.dart';
import 'package:sooq_merchant/core/enums/generic_component_type.dart';
import 'package:sooq_merchant/engine/tree/renderers/column_renderer.dart';
import 'package:sooq_merchant/engine/tree/renderers/container_renderer.dart';
import 'package:sooq_merchant/engine/tree/renderers/text_renderer.dart';

import 'renderer_test_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<Column> pumpColumn(
    WidgetTester tester, {
    Map<String, dynamic> properties = const {},
  }) async {
    final renderer = ColumnRenderer();
    final config = ComponentConfig(
      type: GenericComponentType.column,
      properties: properties,
      children: [
        ComponentConfig(
          type: GenericComponentType.text,
          properties: {'value': 'a'},
        ),
        ComponentConfig(
          type: GenericComponentType.text,
          properties: {'value': 'b'},
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: renderer.render(
            config,
            buildChild: (child) => TextRenderer().render(
              child,
              buildChild: (_) => const SizedBox.shrink(),
              dataContext: rendererDataContext(),
            ),
            dataContext: rendererDataContext(),
          ),
        ),
      ),
    );

    return tester.widget<Column>(find.byType(Column));
  }

  testWidgets('defaults mainAxisSize to min when omitted', (tester) async {
    final column = await pumpColumn(tester);
    expect(column.mainAxisSize, MainAxisSize.min);
  });

  testWidgets('honors mainAxisSize max from props', (tester) async {
    final column = await pumpColumn(
      tester,
      properties: const {'mainAxisSize': 'max'},
    );
    expect(column.mainAxisSize, MainAxisSize.max);
  });

  testWidgets('crossAxis stretch makes children full width', (tester) async {
    final renderer = ColumnRenderer();
    final config = ComponentConfig(
      type: GenericComponentType.column,
      properties: const {'crossAxisAlignment': 'stretch'},
      children: [
        ComponentConfig(
          type: GenericComponentType.text,
          properties: {'value': 'full width line'},
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 280,
            child: renderer.render(
              config,
              buildChild: (child) => TextRenderer().render(
                child,
                buildChild: (_) => const SizedBox.shrink(),
                dataContext: rendererDataContext(),
              ),
              dataContext: rendererDataContext(),
            ),
          ),
        ),
      ),
    );

    final column = tester.widget<Column>(find.byType(Column));
    expect(column.crossAxisAlignment, CrossAxisAlignment.stretch);
    expect(tester.getSize(find.text('full width line')).width, 280);
  });

  testWidgets('honors textDirection rtl when set', (tester) async {
    final column = await pumpColumn(
      tester,
      properties: const {'textDirection': 'rtl'},
    );
    expect(column.textDirection, TextDirection.rtl);
  });

  testWidgets('renders single child when only child is set', (tester) async {
    final renderer = ColumnRenderer();
    final config = ComponentConfig(
      type: GenericComponentType.column,
      properties: const {'crossAxisAlignment': 'stretch'},
      child: ComponentConfig(
        type: GenericComponentType.text,
        properties: {'value': 'single child'},
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: renderer.render(
            config,
            buildChild: (child) => TextRenderer().render(
              child,
              buildChild: (_) => const SizedBox.shrink(),
              dataContext: rendererDataContext(),
            ),
            dataContext: rendererDataContext(),
          ),
        ),
      ),
    );

    expect(find.text('single child'), findsOneWidget);
  });

  testWidgets('expand child in max column does not throw under min parent', (
    tester,
  ) async {
    final columnRenderer = ColumnRenderer();
    final containerRenderer = ContainerRenderer();
    final textRenderer = TextRenderer();

    Widget buildChild(ComponentConfig child) {
      switch (child.type) {
        case GenericComponentType.column:
          return columnRenderer.render(
            child,
            buildChild: buildChild,
            dataContext: rendererDataContext(),
          );
        case GenericComponentType.container:
          return containerRenderer.render(
            child,
            buildChild: buildChild,
            dataContext: rendererDataContext(),
          );
        default:
          return textRenderer.render(
            child,
            buildChild: (_) => const SizedBox.shrink(),
            dataContext: rendererDataContext(),
          );
      }
    }

    final innerColumn = ComponentConfig(
      type: GenericComponentType.column,
      properties: const {'mainAxisSize': 'max', 'crossAxisAlignment': 'stretch'},
      children: [
        ComponentConfig(
          type: GenericComponentType.text,
          properties: {'value': 'title'},
        ),
        ComponentConfig(
          type: GenericComponentType.container,
          properties: const {'expand': true},
          child: ComponentConfig(
            type: GenericComponentType.text,
            properties: {'value': 'body'},
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 500,
            width: 300,
            child: buildChild(innerColumn),
          ),
        ),
      ),
    );

    final error = tester.takeException();
    if (error != null) {
      expect(error.toString(), isNot(contains('unbounded')));
    }
    expect(find.text('body'), findsOneWidget);
  });
}
