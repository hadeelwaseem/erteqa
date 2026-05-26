import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:sooq_merchant/config/component_config.dart';
import 'package:sooq_merchant/core/enums/generic_component_type.dart';
import 'package:sooq_merchant/engine/tree/renderers/column_renderer.dart';
import 'package:sooq_merchant/engine/tree/renderers/container_renderer.dart';
import 'package:sooq_merchant/engine/tree/renderers/image_renderer.dart';
import 'package:sooq_merchant/engine/tree/renderers/text_renderer.dart';

import 'renderer_test_utils.dart';

const _requestKey = 'product-detail';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('loading phase shows Skeletonizer not spinner', (tester) async {
    final renderer = ContainerRenderer();
    final config = ComponentConfig(
      type: GenericComponentType.container,
      properties: {
        'data': {'requestKey': _requestKey},
        'padding': 16,
      },
      child: ComponentConfig(
        type: GenericComponentType.column,
        children: [
          ComponentConfig(
            type: GenericComponentType.image,
            properties: {
              'source': 'network',
              'urlPath':
                  'dataContext.requests.product-detail.data.primaryImageUrl',
              'height': 200,
            },
          ),
          ComponentConfig(
            type: GenericComponentType.text,
            properties: {
              'valuePath': 'dataContext.requests.product-detail.data.name',
            },
          ),
        ],
      ),
    );
    final dataContext = requestLoadingDataContext(_requestKey);

    Widget buildTree(ComponentConfig c, [Map<String, dynamic>? parentCtx]) {
      final base = parentCtx ?? dataContext;
      final ctx = mergeRendererContext(base, c);
      switch (c.type) {
        case GenericComponentType.column:
          return ColumnRenderer().render(
            c,
            buildChild: (inner) => buildTree(inner, ctx),
            dataContext: ctx,
          );
        case GenericComponentType.text:
          return TextRenderer().render(
            c,
            buildChild: (_) => const SizedBox.shrink(),
            dataContext: ctx,
          );
        case GenericComponentType.image:
          return ImageRenderer().render(
            c,
            buildChild: (_) => const SizedBox.shrink(),
            dataContext: ctx,
          );
        default:
          return const SizedBox.shrink();
      }
    }

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: renderer.render(
            config,
            buildChild: (c) => buildTree(c),
            dataContext: dataContext,
          ),
        ),
      ),
    );

    expect(
      find.byWidgetPredicate((w) => w is Skeletonizer),
      findsOneWidget,
    );
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('error phase shows placeholder not skeleton', (tester) async {
    final renderer = ContainerRenderer();
    const arabicError = 'تعذر التحميل';
    final config = ComponentConfig(
      type: GenericComponentType.container,
      properties: {
        'data': {'requestKey': _requestKey},
        'errorMessage': arabicError,
      },
      child: ComponentConfig(
        type: GenericComponentType.text,
        properties: {
          'valuePath': 'dataContext.requests.product-detail.data.name',
        },
      ),
    );
    final dataContext = {
      ...rendererDataContext(),
      'requests': {
        _requestKey: {'success': false, 'message': 'fail'},
      },
    };

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: renderer.render(
            config,
            buildChild: (c) => TextRenderer().render(
              c,
              buildChild: (_) => const SizedBox.shrink(),
              dataContext: mergeRendererContext(dataContext, c),
            ),
            dataContext: dataContext,
          ),
        ),
      ),
    );

    expect(find.text(arabicError), findsOneWidget);
    expect(
      find.byWidgetPredicate((w) => w is Skeletonizer),
      findsNothing,
    );
  });
}
