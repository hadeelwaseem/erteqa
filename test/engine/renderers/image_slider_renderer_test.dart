import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sooq_merchant/config/component_config.dart';
import 'package:sooq_merchant/core/enums/generic_component_type.dart';
import 'package:sooq_merchant/engine/tree/renderers/image_slider_renderer.dart';

import 'renderer_test_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('single image does not build PageView', (tester) async {
    final renderer = ImageSliderRenderer();
    final config = ComponentConfig(
      type: GenericComponentType.imageSlider,
      properties: {
        'images': ['https://example.com/hero.jpg'],
        'fit': 'cover',
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

    expect(find.byType(PageView), findsNothing);
  });

  testWidgets('multiple images build PageView and indicator dots', (tester) async {
    final renderer = ImageSliderRenderer();
    final config = ComponentConfig(
      type: GenericComponentType.imageSlider,
      properties: {
        'images': [
          'https://example.com/a.jpg',
          'https://example.com/b.jpg',
        ],
        'intervalMs': 500,
        'showIndicators': true,
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

    expect(find.byType(PageView), findsOneWidget);
    expect(find.byType(AnimatedContainer), findsNWidgets(2));
  });

  testWidgets('autoPlay false keeps first page after delay', (tester) async {
    final renderer = ImageSliderRenderer();
    final config = ComponentConfig(
      type: GenericComponentType.imageSlider,
      properties: {
        'images': [
          'https://example.com/a.jpg',
          'https://example.com/b.jpg',
        ],
        'intervalMs': 100,
        'autoPlay': false,
      },
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 400,
            width: 400,
            child: renderer.render(
              config,
              buildChild: (_) => const SizedBox.shrink(),
              dataContext: rendererDataContext(),
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    final controller = tester.widget<PageView>(find.byType(PageView)).controller;
    expect(controller?.page?.round(), 0);

    await tester.pump(const Duration(milliseconds: 300));
    expect(controller?.page?.round(), 0);
  });

  testWidgets('manual swipe advances PageView', (tester) async {
    final renderer = ImageSliderRenderer();
    final config = ComponentConfig(
      type: GenericComponentType.imageSlider,
      properties: {
        'images': [
          'https://example.com/a.jpg',
          'https://example.com/b.jpg',
        ],
        'autoPlay': false,
      },
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 400,
            width: 400,
            child: renderer.render(
              config,
              buildChild: (_) => const SizedBox.shrink(),
              dataContext: rendererDataContext(),
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.drag(find.byType(PageView), const Offset(-350, 0));
    await tester.pumpAndSettle();

    final controller = tester.widget<PageView>(find.byType(PageView)).controller;
    expect(controller?.page?.round(), 1);
  });
}
