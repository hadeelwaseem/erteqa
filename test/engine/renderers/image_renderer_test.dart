import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sooq_merchant/config/component_config.dart';
import 'package:sooq_merchant/core/enums/generic_component_type.dart';
import 'package:sooq_merchant/core/widgets/engine_network_image.dart';
import 'package:sooq_merchant/engine/skeleton/skeleton_item_factory.dart';
import 'package:sooq_merchant/engine/tree/renderers/image_renderer.dart';

import 'renderer_test_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('skeletonMode skips network image', (tester) async {
    final renderer = ImageRenderer();
    final config = ComponentConfig(
      type: GenericComponentType.image,
      properties: {
        'source': 'network',
        'urlPath': 'item.image',
        'url': 'https://example.com/fallback.png',
        'aspectRatio': 1,
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
              SkeletonItemFactory.skeletonModeKey: true,
              'item': SkeletonItemFactory.itemAt(0),
            },
          ),
        ),
      ),
    );

    expect(find.byType(EngineNetworkImage), findsNothing);
    expect(find.byType(AspectRatio), findsOneWidget);
  });

  testWidgets('urlPath item.image resolves from list item map', (tester) async {
    final renderer = ImageRenderer();
    const url =
        'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=200&q=80';
    final config = ComponentConfig(
      type: GenericComponentType.image,
      properties: {
        'source': 'network',
        'urlPath': 'item.image',
        'url': 'https://example.com/fallback.png',
        'height': 120,
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
              'item': {'name': 'منتج تجريبي 1', 'image': url},
            },
          ),
        ),
      ),
    );

    final networkImage = tester.widget<EngineNetworkImage>(
      find.byType(EngineNetworkImage),
    );
    expect(networkImage.url, url);
  });

  testWidgets('empty urlPath uses props url fallback', (tester) async {
    final renderer = ImageRenderer();
    const fallback = 'https://example.com/fallback.png';
    final config = ComponentConfig(
      type: GenericComponentType.image,
      properties: {
        'source': 'network',
        'urlPath': 'item.image',
        'url': fallback,
        'height': 120,
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
              'item': {'name': 'منتج', 'image': ''},
            },
          ),
        ),
      ),
    );

    final networkImage = tester.widget<EngineNetworkImage>(
      find.byType(EngineNetworkImage),
    );
    expect(networkImage.url, fallback);
  });

  testWidgets('urlPath resolves to EngineNetworkImage', (tester) async {
    final renderer = ImageRenderer();
    const url = 'https://example.com/product.png';
    final config = ComponentConfig(
      type: GenericComponentType.image,
      properties: {
        'source': 'network',
        'urlPath': 'item.imageUrl',
        'width': 48,
        'height': 48,
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
              'item': {'imageUrl': url},
            },
          ),
        ),
      ),
    );

    final networkImage = tester.widget<EngineNetworkImage>(
      find.byType(EngineNetworkImage),
    );
    expect(networkImage.url, url);
  });

  testWidgets('empty network url shows placeholder icon', (tester) async {
    final renderer = ImageRenderer();
    final config = ComponentConfig(
      type: GenericComponentType.image,
      properties: {'source': 'network', 'url': '', 'width': 40, 'height': 40},
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

    expect(find.byIcon(Icons.image_outlined), findsOneWidget);
  });

  testWidgets('alt prop sets semantics label', (tester) async {
    final renderer = ImageRenderer();
    final config = ComponentConfig(
      type: GenericComponentType.image,
      properties: {
        'source': 'network',
        'url': 'https://example.com/photo.png',
        'alt': 'Product photo',
        'width': 48,
        'height': 48,
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

    expect(find.bySemanticsLabel('Product photo'), findsOneWidget);
  });

  testWidgets('semanticsLabel takes priority over alt', (tester) async {
    final renderer = ImageRenderer();
    final config = ComponentConfig(
      type: GenericComponentType.image,
      properties: {
        'source': 'network',
        'url': 'https://example.com/photo.png',
        'semanticsLabel': 'Primary label',
        'alt': 'Alt text',
        'width': 48,
        'height': 48,
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

    expect(find.bySemanticsLabel('Primary label'), findsOneWidget);
    expect(find.bySemanticsLabel('Alt text'), findsNothing);
  });
}
