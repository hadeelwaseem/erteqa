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

  testWidgets('single image shows indicator when explicitly enabled', (
    tester,
  ) async {
    final renderer = ImageSliderRenderer();
    final config = ComponentConfig(
      type: GenericComponentType.imageSlider,
      properties: {
        'images': ['https://example.com/hero.jpg'],
        'showIndicators': true,
        'showIndicatorsWhenSingle': true,
      },
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 320,
            width: 360,
            child: renderer.render(
              config,
              buildChild: (_) => const SizedBox.shrink(),
              dataContext: rendererDataContext(),
            ),
          ),
        ),
      ),
    );

    expect(find.byType(PageView), findsNothing);
    expect(find.byType(AnimatedContainer), findsOneWidget);
  });

  testWidgets('single image shows thumbnail when explicitly enabled', (
    tester,
  ) async {
    final renderer = ImageSliderRenderer();
    final config = ComponentConfig(
      type: GenericComponentType.imageSlider,
      properties: {
        'images': ['https://example.com/hero.jpg'],
        'showThumbnails': true,
        'showThumbnailsWhenSingle': true,
      },
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 360,
            width: 360,
            child: renderer.render(
              config,
              buildChild: (_) => const SizedBox.shrink(),
              dataContext: rendererDataContext(),
            ),
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('engine-image-slider-thumb-0')), findsOneWidget);
  });

  testWidgets('single image keeps controls hidden by default', (tester) async {
    final renderer = ImageSliderRenderer();
    final config = ComponentConfig(
      type: GenericComponentType.imageSlider,
      properties: {
        'images': ['https://example.com/hero.jpg'],
        'showIndicators': true,
        'showThumbnails': true,
      },
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 360,
            width: 360,
            child: renderer.render(
              config,
              buildChild: (_) => const SizedBox.shrink(),
              dataContext: rendererDataContext(),
            ),
          ),
        ),
      ),
    );

    expect(find.byType(AnimatedContainer), findsNothing);
    expect(find.byKey(const Key('engine-image-slider-thumb-0')), findsNothing);
  });

  testWidgets('empty bound images render safely in scroll view', (tester) async {
    final renderer = ImageSliderRenderer();
    final config = ComponentConfig(
      type: GenericComponentType.imageSlider,
      properties: {
        'imagesPath': 'dataContext.requests.product-detail.data.images',
        'aspectRatio': 1.5,
      },
    );

    final dataContext = rendererDataContext()
      ..addAll({
        'requests': {
          'product-detail': {
            'data': {'images': []},
          },
        },
      });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: renderer.render(
              config,
              buildChild: (_) => const SizedBox.shrink(),
              dataContext: dataContext,
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byIcon(Icons.image_outlined), findsOneWidget);
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
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    final controller = tester.widget<PageView>(find.byType(PageView)).controller;
    expect(controller?.page?.round(), 1);
  });

  testWidgets('binds images from imagesPath in dataContext', (tester) async {
    final renderer = ImageSliderRenderer();
    final config = ComponentConfig(
      type: GenericComponentType.imageSlider,
      properties: {
        'imagesPath': 'dataContext.requests.product-detail.data.images',
        'itemUrlPath': 'publicUrl',
        'showIndicators': true,
      },
    );

    final dataContext = rendererDataContext()
      ..addAll({
        'requests': {
          'product-detail': {
            'data': {
              'images': [
                {'publicUrl': 'https://example.com/a.jpg'},
                {'publicUrl': 'https://example.com/b.jpg'},
              ],
            },
          },
        },
      });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 400,
            width: 400,
            child: renderer.render(
              config,
              buildChild: (_) => const SizedBox.shrink(),
              dataContext: dataContext,
            ),
          ),
        ),
      ),
    );

    expect(find.byType(PageView), findsOneWidget);
    expect(find.byType(AnimatedContainer), findsNWidgets(2));
  });

  testWidgets('thumbnails tap switches active slide', (tester) async {
    final renderer = ImageSliderRenderer();
    final config = ComponentConfig(
      type: GenericComponentType.imageSlider,
      properties: {
        'images': [
          'https://example.com/a.jpg',
          'https://example.com/b.jpg',
        ],
        'showThumbnails': true,
        'autoPlay': false,
      },
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 420,
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
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.byKey(const Key('engine-image-slider-thumb-1')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    final controller = tester.widget<PageView>(find.byType(PageView)).controller;
    expect(controller?.page?.round(), 1);
  });

  testWidgets('tapping main slider opens fullscreen preview', (tester) async {
    final renderer = ImageSliderRenderer();
    final config = ComponentConfig(
      type: GenericComponentType.imageSlider,
      properties: {
        'images': [
          'https://example.com/a.jpg',
          'https://example.com/b.jpg',
        ],
        'enableFullscreenPreview': true,
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

    await tester.tap(find.byType(PageView));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(Dialog), findsOneWidget);

    await tester.tap(find.byKey(const Key('engine-image-slider-fullscreen-close')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(Dialog), findsNothing);
  });
}
