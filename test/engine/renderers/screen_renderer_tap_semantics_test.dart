import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sooq_merchant/config/component_config.dart';
import 'package:sooq_merchant/config/screen_config.dart';
import 'package:sooq_merchant/core/enums/generic_component_type.dart';
import 'package:sooq_merchant/engine/screen_renderer/screen_renderer.dart';

import 'renderer_test_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('tappable card exposes button semantics with accessibilityLabel', (
    tester,
  ) async {
    final screenRenderer = ScreenRenderer.withPrimitives();
    final screen = ScreenConfig(
      pageId: 'test',
      pageName: 'Test',
      root: ComponentConfig(
        type: GenericComponentType.card,
        properties: {
          'accessibilityLabel': 'Product',
          'tap': {'type': 'navigate', 'route': '/home'},
        },
        child: ComponentConfig(
          type: GenericComponentType.text,
          properties: {'value': 'Tile'},
        ),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => screenRenderer.render(
            screen,
            context: context,
            dataContext: rendererDataContext(),
          ),
        ),
      ),
    );

    final semantics = tester.getSemantics(find.bySemanticsLabel('Product'));
    expect(semantics.label, 'Product');
    expect(semantics.hasFlag(SemanticsFlag.isButton), isTrue);
  });
}
