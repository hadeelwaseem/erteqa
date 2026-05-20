import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sooq_merchant/config/component_config.dart';
import 'package:sooq_merchant/core/enums/generic_component_type.dart';
import 'package:sooq_merchant/engine/tree/renderers/image_renderer.dart';

import 'renderer_test_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('urlPath resolves to Image.network', (tester) async {
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

    final image = tester.widget<Image>(find.byType(Image));
    expect(image.image, isA<NetworkImage>());
    expect((image.image as NetworkImage).url, url);
  });

  testWidgets('errorBuilder shows broken_image icon for invalid URL', (
    tester,
  ) async {
    final renderer = ImageRenderer();
    final config = ComponentConfig(
      type: GenericComponentType.image,
      properties: {
        'source': 'network',
        'url': 'https://invalid.invalid.example/nope.png',
        'width': 40,
        'height': 40,
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

    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    expect(find.byIcon(Icons.broken_image), findsOneWidget);
  });
}
