import 'package:flutter/material.dart';

import 'package:flutter_test/flutter_test.dart';

import 'package:sooq_merchant/config/component_config.dart';

import 'package:sooq_merchant/core/enums/generic_component_type.dart';

import 'package:sooq_merchant/engine/theme/shadow_tokens.dart';

import 'package:sooq_merchant/engine/tree/renderers/card_renderer.dart';

import 'package:sooq_merchant/engine/tree/renderers/container_renderer.dart';

import 'renderers/renderer_test_utils.dart';

/// Verifies Pass A JSON shadow/elevation values render as expected.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Visual hierarchy pass A', () {
    testWidgets('cart-checkout-panel elevation 8', (tester) async {
      final renderer = CardRenderer();
      final config = ComponentConfig(
        type: GenericComponentType.card,
        properties: {
          'color': '#FFFFFF',
          'borderRadius': 16,
          'elevation': 8,
        },
        child: ComponentConfig(
          type: GenericComponentType.text,
          properties: {'value': 'summary'},
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            backgroundColor: const Color(0xFFF1F5F9),
            body: renderer.render(
              config,
              buildChild: (child) => Text(child.properties['value'] as String),
              dataContext: rendererDataContext(),
            ),
          ),
        ),
      );

      final card = tester.widget<Card>(find.byType(Card));
      expect(card.elevation, 8);
      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('goldens/cart_checkout_panel_elevation_8.png'),
      );
    });

    testWidgets('product-info-block elevation 6', (tester) async {
      final renderer = CardRenderer();
      final config = ComponentConfig(
        type: GenericComponentType.card,
        properties: {
          'color': '#FFFFFF',
          'borderRadius': 12,
          'elevation': 6,
        },
        child: ComponentConfig(
          type: GenericComponentType.text,
          properties: {'value': 'Product name'},
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            backgroundColor: const Color(0xFFF1F5F9),
            body: renderer.render(
              config,
              buildChild: (child) => Text(child.properties['value'] as String),
              dataContext: rendererDataContext(),
            ),
          ),
        ),
      );

      final card = tester.widget<Card>(find.byType(Card));
      expect(card.elevation, 6);
      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('goldens/product_info_block_elevation_6.png'),
      );
    });

    testWidgets('autocomplete panel shadow xl', (tester) async {
      final renderer = ContainerRenderer();
      final config = ComponentConfig(
        type: GenericComponentType.container,
        properties: {
          'color': '#FFFFFF',
          'borderRadius': 10,
          'shadow': 'xl',
        },
        child: ComponentConfig(
          type: GenericComponentType.text,
          properties: {'value': 'Suggestion'},
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            backgroundColor: const Color(0xFFF1F5F9),
            body: renderer.render(
              config,
              buildChild: (child) => Text(child.properties['value'] as String),
              dataContext: rendererDataContext(),
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container).first);
      final decoration = container.decoration! as BoxDecoration;
      expect(decoration.boxShadow, [ShadowTokens.xl]);
      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('goldens/autocomplete_panel_shadow_xl.png'),
      );
    });
  });
}
