import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sooq_merchant/config/component_config.dart';
import 'package:sooq_merchant/core/enums/generic_component_type.dart';
import 'package:sooq_merchant/engine/tree/renderers/list_view_renderer.dart';
import 'package:sooq_merchant/engine/tree/renderers/single_child_scroll_view_renderer.dart';
import 'package:sooq_merchant/engine/tree/renderers/text_renderer.dart';

import 'renderer_test_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('nested listView skips outer SingleChildScrollView', (
    tester,
  ) async {
    final renderer = SingleChildScrollViewRenderer();
    final config = ComponentConfig(
      type: GenericComponentType.singleChildScrollView,
      child: ComponentConfig(
        type: GenericComponentType.listView,
        properties: {'enableInnerScroll': false},
        children: [
          ComponentConfig(
            type: GenericComponentType.text,
            properties: {'value': 'item'},
          ),
        ],
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: renderer.render(
            config,
            buildChild: (child) {
              if (child.type == GenericComponentType.listView) {
                return ListViewRenderer().render(
                  child,
                  buildChild: (c) => TextRenderer().render(
                    c,
                    buildChild: (_) => const SizedBox.shrink(),
                    dataContext: rendererDataContext(),
                  ),
                  dataContext: rendererDataContext(),
                );
              }
              return const SizedBox.shrink();
            },
            dataContext: rendererDataContext(),
          ),
        ),
      ),
    );

    expect(find.byType(SingleChildScrollView), findsNothing);
  });
}
