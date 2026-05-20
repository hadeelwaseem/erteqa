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

  testWidgets('asymmetric padding uses directional start/end in RTL', (
    tester,
  ) async {
    final renderer = ContainerRenderer();
    final config = ComponentConfig(
      type: GenericComponentType.container,
      properties: {
        'padding': {'left': 8, 'right': 24, 'top': 0, 'bottom': 0},
      },
      child: ComponentConfig(
        type: GenericComponentType.text,
        properties: {'value': 'x'},
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: renderer.render(
              config,
              buildChild: (_) => const SizedBox.shrink(),
              dataContext: rendererDataContext(),
            ),
          ),
        ),
      ),
    );

    final container = tester.widget<Container>(find.byType(Container));
    final padding = container.padding! as EdgeInsetsDirectional;
    expect(padding.start, 8);
    expect(padding.end, 24);
  });

  testWidgets('expand uses minHeight inside scroll (splash layout)', (
    tester,
  ) async {
    final containerRenderer = ContainerRenderer();
    final columnRenderer = ColumnRenderer();
    final textRenderer = TextRenderer();

    Widget buildChild(ComponentConfig child) {
      if (child.type == GenericComponentType.column) {
        return columnRenderer.render(
          child,
          buildChild: buildChild,
          dataContext: rendererDataContext(),
        );
      }
      return textRenderer.render(
        child,
        buildChild: (_) => const SizedBox.shrink(),
        dataContext: rendererDataContext(),
      );
    }

    const viewportHeight = 400.0;
    final config = ComponentConfig(
      type: GenericComponentType.container,
      properties: const {'expand': true},
      child: ComponentConfig(
        type: GenericComponentType.column,
        properties: const {
          'mainAxisAlignment': 'center',
          'mainAxisSize': 'max',
        },
        children: [
          ComponentConfig(
            type: GenericComponentType.text,
            properties: {'value': 'centered'},
          ),
        ],
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: viewportHeight),
              child: containerRenderer.render(
                config,
                buildChild: buildChild,
                dataContext: rendererDataContext(),
              ),
            ),
          ),
        ),
      ),
    );

    final offset = tester.getTopLeft(find.text('centered'));
    expect(offset.dy, greaterThan(100));
    expect(offset.dy, lessThan(300));
  });

  testWidgets('expand fills bounded parent so column can center vertically', (
    tester,
  ) async {
    final containerRenderer = ContainerRenderer();
    final columnRenderer = ColumnRenderer();
    final textRenderer = TextRenderer();

    Widget buildChild(ComponentConfig child) {
      if (child.type == GenericComponentType.column) {
        return columnRenderer.render(
          child,
          buildChild: buildChild,
          dataContext: rendererDataContext(),
        );
      }
      return textRenderer.render(
        child,
        buildChild: (_) => const SizedBox.shrink(),
        dataContext: rendererDataContext(),
      );
    }

    final config = ComponentConfig(
      type: GenericComponentType.container,
      properties: const {'expand': true},
      child: ComponentConfig(
        type: GenericComponentType.column,
        properties: const {
          'mainAxisAlignment': 'center',
          'mainAxisSize': 'max',
        },
        children: [
          ComponentConfig(
            type: GenericComponentType.text,
            properties: {'value': 'centered'},
          ),
        ],
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 400,
            width: 300,
            child: containerRenderer.render(
              config,
              buildChild: buildChild,
              dataContext: rendererDataContext(),
            ),
          ),
        ),
      ),
    );

    expect(find.byType(SizedBox), findsWidgets);
    final offset = tester.getTopLeft(find.text('centered'));
    expect(offset.dy, greaterThan(100));
    expect(offset.dy, lessThan(300));
  });
}
