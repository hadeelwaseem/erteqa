import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sooq_merchant/config/component_config.dart';
import 'package:sooq_merchant/core/enums/generic_component_type.dart';
import 'package:sooq_merchant/engine/tree/renderers/card_renderer.dart';
import 'package:sooq_merchant/engine/tree/renderers/text_renderer.dart';

import 'renderer_test_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('theme default borderRadius when props omitted', (tester) async {
    final renderer = CardRenderer();
    final config = ComponentConfig(
      type: GenericComponentType.card,
      child: ComponentConfig(
        type: GenericComponentType.text,
        properties: {'value': 'inside'},
      ),
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

    final card = tester.widget<Card>(find.byType(Card));
    final shape = card.shape as RoundedRectangleBorder;
    expect(shape.borderRadius, BorderRadius.circular(10));
    expect(find.text('inside'), findsOneWidget);
  });

  testWidgets('margin prop wraps Card in Padding', (tester) async {
    final renderer = CardRenderer();
    final config = ComponentConfig(
      type: GenericComponentType.card,
      properties: {
        'margin': {'left': 12, 'top': 4, 'right': 12, 'bottom': 4},
      },
      child: ComponentConfig(
        type: GenericComponentType.text,
        properties: {'value': 'card body'},
      ),
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

    expect(find.byType(Padding), findsWidgets);
    expect(find.byType(Card), findsOneWidget);
    expect(find.text('card body'), findsOneWidget);
  });
}
