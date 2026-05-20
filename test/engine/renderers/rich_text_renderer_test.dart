import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sooq_merchant/config/component_config.dart';
import 'package:sooq_merchant/core/enums/generic_component_type.dart';
import 'package:sooq_merchant/engine/tree/renderers/rich_text_renderer.dart';

import 'renderer_test_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('strips HTML paragraph tags', (tester) async {
    final renderer = RichTextRenderer();
    final config = ComponentConfig(
      type: GenericComponentType.richtext,
      properties: {'value': '<p>Hello</p>'},
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

    expect(find.text('Hello'), findsOneWidget);
    expect(find.textContaining('<p>'), findsNothing);
  });

  testWidgets('decodes HTML entities', (tester) async {
    final renderer = RichTextRenderer();
    final config = ComponentConfig(
      type: GenericComponentType.richtext,
      properties: {'value': 'A &amp; B'},
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

    expect(find.text('A & B'), findsOneWidget);
  });

  testWidgets('valuePath resolves from dataContext', (tester) async {
    final renderer = RichTextRenderer();
    final config = ComponentConfig(
      type: GenericComponentType.richtext,
      properties: {
        'valuePath': 'copy.body',
        'value': 'fallback',
      },
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: renderer.render(
            config,
            buildChild: (_) => const SizedBox.shrink(),
            dataContext: {
              ...rendererDataContext(),
              'copy': {'body': '<p>Dynamic</p>'},
            },
          ),
        ),
      ),
    );

    expect(find.text('Dynamic'), findsOneWidget);
  });
}
