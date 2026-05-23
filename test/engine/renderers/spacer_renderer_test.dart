import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sooq_merchant/config/component_config.dart';
import 'package:sooq_merchant/core/enums/generic_component_type.dart';
import 'package:sooq_merchant/engine/tree/renderers/column_renderer.dart';
import 'package:sooq_merchant/engine/tree/renderers/container_renderer.dart';
import 'package:sooq_merchant/engine/tree/renderers/row_renderer.dart';
import 'package:sooq_merchant/engine/tree/renderers/spacer_renderer.dart';
import 'package:sooq_merchant/engine/tree/renderers/text_renderer.dart';

import 'renderer_test_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final spacerRenderer = SpacerRenderer();

  Widget buildChild(ComponentConfig child) {
    switch (child.type) {
      case GenericComponentType.column:
        return ColumnRenderer().render(
          child,
          buildChild: buildChild,
          dataContext: rendererDataContext(),
        );
      case GenericComponentType.row:
        return RowRenderer().render(
          child,
          buildChild: buildChild,
          dataContext: rendererDataContext(),
        );
      case GenericComponentType.container:
        return ContainerRenderer().render(
          child,
          buildChild: buildChild,
          dataContext: rendererDataContext(),
        );
      case GenericComponentType.text:
        return TextRenderer().render(
          child,
          buildChild: (_) => const SizedBox.shrink(),
          dataContext: rendererDataContext(),
        );
      default:
        return spacerRenderer.render(
          child,
          buildChild: buildChild,
          dataContext: rendererDataContext(),
        );
    }
  }

  Future<void> pumpSpacerTree(
    WidgetTester tester,
    ComponentConfig root,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 300,
            child: buildChild(root),
          ),
        ),
      ),
    );
    final exception = tester.takeException();
    if (exception != null) {
      expect(
        exception.toString(),
        isNot(contains('RenderFlex')),
        reason: exception.toString(),
      );
      expect(
        exception.toString(),
        isNot(contains('unbounded')),
        reason: exception.toString(),
      );
    }
  }

  testWidgets('width and height props render SizedBox not Spacer', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: spacerRenderer.render(
          ComponentConfig(
            type: GenericComponentType.spacer,
            properties: const {'width': 40, 'height': 8},
          ),
          buildChild: buildChild,
          dataContext: rendererDataContext(),
        ),
      ),
    );

    expect(find.byType(Spacer), findsNothing);
    final box = tester.widget<SizedBox>(find.byType(SizedBox));
    expect(box.width, 40);
    expect(box.height, 8);
  });

  testWidgets('spacer in max row uses Spacer when parent width is bounded', (
    tester,
  ) async {
    await pumpSpacerTree(
      tester,
      ComponentConfig(
        type: GenericComponentType.row,
        properties: const {'mainAxisSize': 'max'},
        children: [
          ComponentConfig(
            type: GenericComponentType.text,
            properties: {'value': 'left'},
          ),
          ComponentConfig(
            type: GenericComponentType.spacer,
            properties: const {'flex': 2},
          ),
          ComponentConfig(
            type: GenericComponentType.text,
            properties: {'value': 'right'},
          ),
        ],
      ),
    );

    expect(find.byType(Spacer), findsOneWidget);
    expect(tester.widget<Spacer>(find.byType(Spacer)).flex, 2);
  });

  testWidgets('spacer in min column uses fixed SizedBox not Spacer', (
    tester,
  ) async {
    await pumpSpacerTree(
      tester,
      ComponentConfig(
        type: GenericComponentType.column,
        properties: const {'mainAxisSize': 'min'},
        children: [
          ComponentConfig(
            type: GenericComponentType.text,
            properties: {'value': 'above'},
          ),
          ComponentConfig(
            type: GenericComponentType.spacer,
            properties: const {'flex': 3},
          ),
        ],
      ),
    );

    expect(find.byType(Spacer), findsNothing);
    final sizedBoxes = tester.widgetList<SizedBox>(find.byType(SizedBox));
    expect(sizedBoxes.any((b) => b.height == 48), isTrue);
  });

  testWidgets('spacer under container only uses height fallback', (
    tester,
  ) async {
    await pumpSpacerTree(
      tester,
      ComponentConfig(
        type: GenericComponentType.container,
        child: ComponentConfig(
          type: GenericComponentType.spacer,
          properties: const {'flex': 1},
        ),
      ),
    );

    expect(find.byType(Spacer), findsNothing);
    final sizedBoxes = tester.widgetList<SizedBox>(find.byType(SizedBox));
    expect(
      sizedBoxes.any((b) => b.height == 16),
      isTrue,
    );
  });
}
