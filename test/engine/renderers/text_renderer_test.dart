import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sooq_merchant/config/component_config.dart';
import 'package:sooq_merchant/core/enums/generic_component_type.dart';
import 'package:sooq_merchant/engine/tree/renderers/text_renderer.dart';

import 'renderer_test_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('maxLines and overflow ellipsis apply to Text', (tester) async {
    final renderer = TextRenderer();
    final config = ComponentConfig(
      type: GenericComponentType.text,
      properties: {
        'value': 'Long product title that should truncate',
        'maxLines': 1,
        'overflow': 'ellipsis',
      },
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: renderer.render(
            config,
            buildChild: (_) => const SizedBox.shrink(),
            dataContext: rendererDataContext(),
          ),
        ),
      ),
    );

    final text = tester.widget<Text>(find.byType(Text));
    expect(text.maxLines, 1);
    expect(text.overflow, TextOverflow.ellipsis);
  });

  testWidgets('maxLines accepts JSON number (not only int)', (tester) async {
    final renderer = TextRenderer();
    final config = ComponentConfig(
      type: GenericComponentType.text,
      properties: {
        'value': 'Line',
        'maxLines': 2.0,
      },
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: renderer.render(
            config,
            buildChild: (_) => const SizedBox.shrink(),
            dataContext: rendererDataContext(),
          ),
        ),
      ),
    );

    expect(tester.widget<Text>(find.byType(Text)).maxLines, 2);
  });
}

