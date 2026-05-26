import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:sooq_merchant/config/component_config.dart';
import 'package:sooq_merchant/core/enums/generic_component_type.dart';
import 'package:sooq_merchant/core/widgets/engine_network_image.dart';
import 'package:sooq_merchant/engine/tree/renderers/grid_view_renderer.dart';
import 'package:sooq_merchant/engine/tree/renderers/image_renderer.dart';

import 'renderer_test_utils.dart';

const _requestKey = 'home-featured-products';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('loading grid with image tile does not load network', (
    tester,
  ) async {
    final gridRenderer = GridViewRenderer();
    final imageRenderer = ImageRenderer();
    final dataContext = requestLoadingDataContext(_requestKey);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: gridRenderer.render(
            ComponentConfig(
              type: GenericComponentType.gridView,
              crossAxisCount: 2,
              properties: {
                'data': {'requestKey': _requestKey, 'size': 6},
                'childAspectRatio': 0.68,
              },
              itemBuilder: ItemBuilderConfig(
                source: 'dataContext.requests.$_requestKey.data',
                item: ComponentConfig(
                  type: GenericComponentType.image,
                  properties: {
                    'source': 'network',
                    'urlPath': 'item.image',
                    'url': 'https://example.com/fallback.png',
                    'aspectRatio': 1,
                  },
                ),
              ),
            ),
            buildChild: (c) {
              final merged = mergeRendererContext(dataContext, c);
              return imageRenderer.render(
                c,
                buildChild: (_) => const SizedBox.shrink(),
                dataContext: merged,
              );
            },
            dataContext: dataContext,
          ),
        ),
      ),
    );

    expect(
      find.byWidgetPredicate((w) => w is Skeletonizer),
      findsOneWidget,
    );
    expect(find.byType(EngineNetworkImage), findsNothing);
  });
}
