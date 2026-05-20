import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sooq_merchant/config/component_config.dart';
import 'package:sooq_merchant/core/enums/generic_component_type.dart';
import 'package:sooq_merchant/engine/tree/renderers/column_renderer.dart';
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

  testWidgets('honors textDirection rtl when set', (tester) async {
    final column = await pumpColumn(
      tester,
      properties: const {'textDirection': 'rtl'},
    );
    expect(column.textDirection, TextDirection.rtl);
  });
}
