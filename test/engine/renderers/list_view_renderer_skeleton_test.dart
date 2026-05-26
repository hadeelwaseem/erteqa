import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:sooq_merchant/config/component_config.dart';
import 'package:sooq_merchant/core/enums/generic_component_type.dart';
import 'package:sooq_merchant/engine/tree/renderers/list_view_renderer.dart';
import 'package:sooq_merchant/engine/tree/renderers/text_renderer.dart';

import 'renderer_test_utils.dart';

const _requestKey = 'home-categories';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('loading phase shows Skeletonizer not spinner', (tester) async {
    final renderer = ListViewRenderer();
    final config = ComponentConfig(
      type: GenericComponentType.listView,
      properties: {
        'data': {'requestKey': _requestKey, 'size': 6},
      },
      itemBuilder: ItemBuilderConfig(
        source: 'dataContext.requests.$_requestKey.data',
        item: ComponentConfig(
          type: GenericComponentType.text,
          properties: {'valuePath': 'item.name'},
        ),
      ),
    );
    final dataContext = requestLoadingDataContext(_requestKey);

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

    expect(
      find.byWidgetPredicate((w) => w is Skeletonizer),
      findsOneWidget,
    );
    expect(find.byType(ListView), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('error phase shows placeholder not skeleton', (tester) async {
    final renderer = ListViewRenderer();
    const arabicError = 'تعذر التحميل';
    final config = ComponentConfig(
      type: GenericComponentType.listView,
      properties: {
        'data': {'requestKey': _requestKey},
        'errorMessage': arabicError,
      },
      itemBuilder: ItemBuilderConfig(
        source: 'dataContext.requests.$_requestKey.data',
        item: ComponentConfig(
          type: GenericComponentType.text,
          properties: {'valuePath': 'item.name'},
        ),
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
