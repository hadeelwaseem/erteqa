import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sooq_merchant/config/component_config.dart';
import 'package:sooq_merchant/core/enums/generic_component_type.dart';
import 'package:sooq_merchant/engine/tree/renderers/container_renderer.dart';

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
}
