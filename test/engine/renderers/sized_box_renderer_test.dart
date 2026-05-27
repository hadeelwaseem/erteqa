import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sooq_merchant/config/component_config.dart';
import 'package:sooq_merchant/core/enums/generic_component_type.dart';
import 'package:sooq_merchant/engine/tree/renderers/sized_box_renderer.dart';
import 'package:sooq_merchant/engine/tree/renderers/text_renderer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('renders fixed height spacing', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBoxRenderer().render(
            ComponentConfig(
              type: GenericComponentType.sizedBox,
              properties: const {'height': 16},
            ),
            buildChild: (_) => const SizedBox.shrink(),
          ),
        ),
      ),
    );

    final box = tester.widget<SizedBox>(find.byType(SizedBox));
    expect(box.height, 16);
    expect(box.width, isNull);
    expect(box.child, isNull);
  });

  testWidgets('renders width and height with optional child', (tester) async {
    final textRenderer = TextRenderer();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBoxRenderer().render(
            ComponentConfig(
              type: GenericComponentType.sizedBox,
              properties: const {'width': 120, 'height': 48},
              child: ComponentConfig(
                type: GenericComponentType.text,
                properties: {'value': 'boxed'},
              ),
            ),
            buildChild: (child) => textRenderer.render(
              child,
              buildChild: (_) => const SizedBox.shrink(),
            ),
          ),
        ),
      ),
    );

    expect(find.text('boxed'), findsOneWidget);
    final box = tester.widget<SizedBox>(find.byType(SizedBox));
    expect(box.width, 120);
    expect(box.height, 48);
  });
}
