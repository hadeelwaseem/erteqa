import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sooq_merchant/config/component_config.dart';
import 'package:sooq_merchant/core/enums/generic_component_type.dart';
import 'package:sooq_merchant/engine/tree/renderers/column_renderer.dart';
import 'package:sooq_merchant/engine/tree/renderers/container_renderer.dart';
import 'package:sooq_merchant/engine/tree/renderers/row_renderer.dart';
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

  testWidgets('expand in row Expanded does not use viewport height', (
    tester,
  ) async {
    final containerRenderer = ContainerRenderer();
    final rowRenderer = RowRenderer();
    final textRenderer = TextRenderer();

    Widget buildChild(ComponentConfig child) {
      switch (child.type) {
        case GenericComponentType.row:
          return rowRenderer.render(
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

    final config = ComponentConfig(
      type: GenericComponentType.row,
      properties: const {'mainAxisAlignment': 'start'},
      children: [
        ComponentConfig(
          type: GenericComponentType.text,
          properties: {'value': 'icon'},
        ),
        ComponentConfig(
          type: GenericComponentType.container,
          properties: const {'expand': true, 'expandAxis': 'horizontal'},
          child: ComponentConfig(
            type: GenericComponentType.text,
            properties: {'value': 'hint'},
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 300,
            child: rowRenderer.render(
              config,
              buildChild: buildChild,
              dataContext: rendererDataContext(),
            ),
          ),
        ),
      ),
    );

    final rowHeight = tester.getSize(find.byType(Row)).height;
    expect(rowHeight, lessThan(80));
    expect(find.text('hint'), findsOneWidget);
  });

  testWidgets('requestKey on container shows loading until data arrives', (
    tester,
  ) async {
    final renderer = ContainerRenderer();
    const requestKey = 'product-detail';
    final config = ComponentConfig(
      type: GenericComponentType.container,
      properties: {
        'data': {'requestKey': requestKey},
        'errorMessage': 'خطأ',
        'emptyMessage': 'فارغ',
      },
      child: ComponentConfig(
        type: GenericComponentType.text,
        properties: {'value': 'يجب ألا يظهر'},
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: renderer.render(
            config,
            buildChild: (c) => TextRenderer().render(
              c,
              buildChild: (_) => const SizedBox.shrink(),
              dataContext: {
                'initialRequestKeys': {requestKey: true},
                'loadingRequestKeys': {requestKey: true},
              },
            ),
            dataContext: {
              'initialRequestKeys': {requestKey: true},
              'loadingRequestKeys': {requestKey: true},
            },
          ),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('يجب ألا يظهر'), findsNothing);
  });
}
