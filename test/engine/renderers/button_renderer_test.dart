import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sooq_merchant/config/component_config.dart';
import 'package:sooq_merchant/core/enums/generic_component_type.dart';
import 'package:sooq_merchant/engine/tree/renderers/button_renderer.dart';

import 'renderer_test_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('enabled false sets onPressed to null on FilledButton', (tester) async {
    final renderer = ButtonRenderer();
    final config = ComponentConfig(
      type: GenericComponentType.button,
      properties: {
        'label': 'Submit',
        'variant': 'elevated',
        'enabled': false,
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

    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);
  });

  testWidgets('elevated variant renders FilledButton', (tester) async {
    final renderer = ButtonRenderer();
    final config = ComponentConfig(
      type: GenericComponentType.button,
      properties: {
        'label': 'Go',
        'variant': 'elevated',
        'onTap': () {},
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

    expect(find.byType(FilledButton), findsOneWidget);
    expect(find.byType(ElevatedButton), findsNothing);
  });
}
