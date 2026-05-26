import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sooq_merchant/config/component_config.dart';
import 'package:sooq_merchant/core/enums/generic_component_type.dart';
import 'package:sooq_merchant/engine/tree/renderers/divider_renderer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('applies height and color from properties', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DividerRenderer().render(
            ComponentConfig(
              type: GenericComponentType.divider,
              properties: {
                'height': 1,
                'thickness': 1,
                'color': '#E5E7EB',
              },
            ),
            buildChild: (_) => const SizedBox.shrink(),
          ),
        ),
      ),
    );

    final divider = tester.widget<Divider>(find.byType(Divider));
    expect(divider.height, 1);
    expect(divider.thickness, 1);
    expect(divider.color, const Color(0xFFE5E7EB));
  });

  testWidgets('wraps divider in margin padding', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DividerRenderer().render(
            ComponentConfig(
              type: GenericComponentType.divider,
              properties: {
                'height': 1,
                'margin': {'left': 16, 'right': 16},
              },
            ),
            buildChild: (_) => const SizedBox.shrink(),
          ),
        ),
      ),
    );

    expect(find.byType(Divider), findsOneWidget);
    final padding = tester.widget<Padding>(
      find.ancestor(of: find.byType(Divider), matching: find.byType(Padding)),
    );
    final insets = padding.padding.resolve(TextDirection.ltr);
    expect(insets.left, 16);
    expect(insets.right, 16);
  });
}
