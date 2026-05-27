import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sooq_merchant/config/component_config.dart';
import 'package:sooq_merchant/core/enums/generic_component_type.dart';
import 'package:sooq_merchant/engine/tree/renderers/container_renderer.dart';
import 'package:sooq_merchant/engine/tree/renderers/row_renderer.dart';
import 'package:sooq_merchant/engine/tree/renderers/text_renderer.dart';

import 'renderer_test_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('expand container in bounded row does not use viewport height', (
    tester,
  ) async {
    final rowRenderer = RowRenderer();
    final containerRenderer = ContainerRenderer();
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

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          height: 56,
          width: 320,
          child: buildChild(
            ComponentConfig(
              type: GenericComponentType.row,
              children: [
                ComponentConfig(
                  type: GenericComponentType.container,
                  properties: const {
                    'expand': true,
                    'expandAxis': 'horizontal',
                  },
                  child: ComponentConfig(
                    type: GenericComponentType.text,
                    properties: {'value': 'field'},
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    final box = tester.getSize(find.text('field'));
    expect(box.height, lessThan(100));
  });
}
