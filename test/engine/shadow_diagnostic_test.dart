import 'package:flutter/material.dart';

import 'package:flutter_test/flutter_test.dart';

import 'package:sooq_merchant/config/component_config.dart';

import 'package:sooq_merchant/core/enums/generic_component_type.dart';

import 'package:sooq_merchant/engine/theme/shadow_tokens.dart';

import 'package:sooq_merchant/engine/tree/renderers/card_renderer.dart';

import 'package:sooq_merchant/engine/tree/renderers/container_renderer.dart';

import 'package:sooq_merchant/features/variantscreen/data/repos/variant_repository.dart';



import 'renderers/renderer_test_utils.dart';



/// Diagnostic evidence for shadow visibility — not a regression gate.

void main() {

  TestWidgetsFlutterBinding.ensureInitialized();



  group('JSON → model pipeline (Pass A nodes)', () {

    final repository = AssetVariantRepository();



    ComponentConfig? findById(ComponentConfig root, String id) {

      if (root.properties['id'] == id) return root;

      if (root.child != null) {

        final found = findById(root.child!, id);

        if (found != null) return found;

      }

      for (final child in root.children ?? const <ComponentConfig>[]) {

        final found = findById(child, id);

        if (found != null) return found;

      }

      return null;

    }



    test('Pass A shadow and elevation values survive parse', () async {

      final home = await repository.loadVariant(

        'mobile_production_v2',

        pageRoute: '/home',

      );

      final panel = findById(home.root, 'home-search-autocomplete-panel');

      expect(panel, isNotNull);

      expect(panel!.properties['shadow'], 'xl');

      expect(panel.properties['color'], '#FFFFFF');



      final search = await repository.loadVariant(

        'mobile_production_v2',

        pageRoute: '/search',

      );

      expect(

        findById(search.root, 'search-autocomplete-panel')?.properties['shadow'],

        'xl',

      );



      final product = await repository.loadVariant(

        'mobile_production_v2',

        pageRoute: '/product/details/:productId',

      );

      expect(

        findById(product.root, 'product-info-block')?.properties['elevation'],

        6,

      );



      final cart = await repository.loadVariant(

        'mobile_production_v2',

        pageRoute: '/cart',

      );

      expect(

        findById(cart.root, 'cart-checkout-panel')?.properties['elevation'],

        8,

      );

    });

  });



  group('Shadow strength comparison goldens', () {

    const pageBg = Color(0xFFF1F5F9);



    Widget cardWithElevation(double elevation) {

      return CardRenderer().render(

        ComponentConfig(

          type: GenericComponentType.card,

          properties: {

            'color': '#FFFFFF',

            'borderRadius': 12,

            'elevation': elevation,

          },

          child: ComponentConfig(

            type: GenericComponentType.container,

            properties: {

              'padding': const {'top': 16, 'bottom': 16, 'left': 16, 'right': 16},

            },

            child: ComponentConfig(

              type: GenericComponentType.text,

              properties: {'value': 'elevation $elevation'},

            ),

          ),

        ),

        buildChild: (child) {

          if (child.type == GenericComponentType.text) {

            return Text(child.properties['value'] as String);

          }

          return ContainerRenderer().render(

            child,

            buildChild: (c) => Text(c.properties['value'] as String),

            dataContext: rendererDataContext(),

          );

        },

        dataContext: rendererDataContext(),

      );

    }



    Widget containerWithShadow(BoxShadow shadow, String label) {

      return ContainerRenderer().render(

        ComponentConfig(

          type: GenericComponentType.container,

          properties: {

            'color': '#FFFFFF',

            'borderRadius': 10,

            'shadow': label,

            'padding': const {'top': 12, 'bottom': 12, 'left': 12, 'right': 12},

          },

          child: ComponentConfig(

            type: GenericComponentType.text,

            properties: {'value': label},

          ),

        ),

        buildChild: (child) => Text(child.properties['value'] as String),

        dataContext: rendererDataContext(),

      );

    }



    testWidgets('Material elevation ladder on page background', (tester) async {

      await tester.binding.setSurfaceSize(const Size(360, 520));

      addTearDown(() => tester.binding.setSurfaceSize(null));



      await tester.pumpWidget(

        MaterialApp(

          theme: ThemeData(useMaterial3: true),

          home: Scaffold(

            backgroundColor: pageBg,

            body: SingleChildScrollView(

              padding: const EdgeInsets.all(24),

              child: Column(

                crossAxisAlignment: CrossAxisAlignment.stretch,

                children: [

                  for (final e in [0.0, 1.0, 2.0, 4.0, 8.0]) ...[

                    cardWithElevation(e),

                    const SizedBox(height: 24),

                  ],

                ],

              ),

            ),

          ),

        ),

      );

      await tester.pumpAndSettle();



      await expectLater(

        find.byType(Scaffold),

        matchesGoldenFile('goldens/diagnostic_elevation_ladder_m3.png'),

      );

    });



    testWidgets('BoxShadow preset ladder on page background', (tester) async {

      await tester.binding.setSurfaceSize(const Size(360, 520));

      addTearDown(() => tester.binding.setSurfaceSize(null));



      const debugStrong = BoxShadow(

        color: Color(0x99000000),

        blurRadius: 24,

        spreadRadius: 2,

        offset: Offset(0, 8),

      );



      await tester.pumpWidget(

        MaterialApp(

          home: Scaffold(

            backgroundColor: pageBg,

            body: SingleChildScrollView(

              padding: const EdgeInsets.all(24),

              child: Column(

                crossAxisAlignment: CrossAxisAlignment.stretch,

                children: [

                  containerWithShadow(ShadowTokens.sm, 'sm'),

                  const SizedBox(height: 20),

                  containerWithShadow(ShadowTokens.md, 'md'),

                  const SizedBox(height: 20),

                  containerWithShadow(ShadowTokens.lg, 'lg'),

                  const SizedBox(height: 20),

                  containerWithShadow(ShadowTokens.xl, 'xl'),

                  const SizedBox(height: 20),

                  Container(

                    padding: const EdgeInsets.all(12),

                    decoration: BoxDecoration(

                      color: Colors.white,

                      borderRadius: BorderRadius.circular(10),

                      boxShadow: const [debugStrong],

                    ),

                    child: const Text('debug strong'),

                  ),

                ],

              ),

            ),

          ),

        ),

      );

      await tester.pumpAndSettle();



      await expectLater(

        find.byType(Scaffold),

        matchesGoldenFile('goldens/diagnostic_boxshadow_ladder.png'),

      );

    });



    testWidgets('lg shadow on dark hero background (contrast failure)', (

      tester,

    ) async {

      await tester.binding.setSurfaceSize(const Size(320, 160));

      addTearDown(() => tester.binding.setSurfaceSize(null));



      await tester.pumpWidget(

        MaterialApp(

          home: Scaffold(

            backgroundColor: pageBg,

            body: Center(

              child: ContainerRenderer().render(

                ComponentConfig(

                  type: GenericComponentType.container,

                  properties: {

                    'color': '#0F172A',

                    'borderRadius': 14,

                    'shadow': 'lg',

                    'padding': 20,

                  },

                  child: ComponentConfig(

                    type: GenericComponentType.text,

                    properties: {'value': 'hero dark + lg shadow'},

                  ),

                ),

                buildChild: (child) => Text(

                  child.properties['value'] as String,

                  style: const TextStyle(color: Colors.white),

                ),

                dataContext: rendererDataContext(),

              ),

            ),

          ),

        ),

      );

      await tester.pumpAndSettle();



      await expectLater(

        find.byType(Scaffold),

        matchesGoldenFile('goldens/diagnostic_lg_on_dark_hero.png'),

      );

    });

  });



  group('ShadowTokens preset values (production)', () {

    test('sm has expected blur and offset', () {

      expect(ShadowTokens.sm.blurRadius, 8);

      expect(ShadowTokens.sm.offset, const Offset(0, 2));

      expect(ShadowTokens.sm.color, const Color(0x33000000));

    });



    test('md has expected blur and offset', () {

      expect(ShadowTokens.md.blurRadius, 16);

      expect(ShadowTokens.md.offset, const Offset(0, 4));

      expect(ShadowTokens.md.color, const Color(0x47000000));

    });



    test('lg has expected blur and offset', () {

      expect(ShadowTokens.lg.blurRadius, 24);

      expect(ShadowTokens.lg.offset, const Offset(0, 6));

      expect(ShadowTokens.lg.color, const Color(0x59000000));

    });



    test('xl has expected blur and offset', () {

      expect(ShadowTokens.xl.blurRadius, 32);

      expect(ShadowTokens.xl.offset, const Offset(0, 8));

      expect(ShadowTokens.xl.color, const Color(0x66000000));

    });

  });

}


