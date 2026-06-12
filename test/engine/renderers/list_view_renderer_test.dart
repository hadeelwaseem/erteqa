import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sooq_merchant/config/component_config.dart';
import 'package:sooq_merchant/core/enums/generic_component_type.dart';
import 'package:sooq_merchant/engine/tree/renderers/list_view_renderer.dart';
import 'package:sooq_merchant/engine/tree/renderers/text_renderer.dart';

import 'renderer_test_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('horizontal listView has bounded height and does not overflow', (
    tester,
  ) async {
    final renderer = ListViewRenderer();
    final config = ComponentConfig(
      type: GenericComponentType.listView,
      properties: {
        'scrollDirection': 'horizontal',
        'height': 72,
        'items': ['a', 'b'],
      },
      itemBuilder: ItemBuilderConfig(
        staticItems: ['a', 'b'],
        item: ComponentConfig(
          type: GenericComponentType.text,
          properties: {'value': 'x'},
        ),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              SizedBox(
                height: 200,
                child: renderer.render(
                  config,
                  buildChild: (c) => TextRenderer().render(
                    c,
                    buildChild: (_) => const SizedBox.shrink(),
                    dataContext: rendererDataContext(),
                  ),
                  dataContext: rendererDataContext(),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(ListView), findsOneWidget);
  });

  testWidgets('empty horizontal list without emptyMessage renders nothing', (
    tester,
  ) async {
    final renderer = ListViewRenderer();
    final config = ComponentConfig(
      type: GenericComponentType.listView,
      properties: {
        'scrollDirection': 'horizontal',
        'height': 72,
      },
      itemBuilder: ItemBuilderConfig(
        source: 'dataContext.items',
        item: ComponentConfig(
          type: GenericComponentType.text,
          properties: {'value': 'x'},
        ),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: renderer.render(
            config,
            buildChild: (c) => TextRenderer().render(
              c,
              buildChild: (_) => const SizedBox.shrink(),
              dataContext: {'items': <dynamic>[]},
            ),
            dataContext: {'items': <dynamic>[]},
          ),
        ),
      ),
    );

    expect(find.text('No items available'), findsNothing);
    expect(find.text('لا توجد عناصر'), findsNothing);
  });

  testWidgets(
    'deferred qField request with phase none does not show emptyMessage',
    (tester) async {
      final renderer = ListViewRenderer();
      final config = ComponentConfig(
        type: GenericComponentType.listView,
        properties: {
          'enableInnerScroll': false,
          'data': {
            'requestKey': 'search-autocomplete',
            'requestUrl': '/api/v1/public/products/autocomplete',
            'qField': 'searchQuery',
          },
          'emptyMessage': 'لا توجد اقتراحات',
        },
        itemBuilder: ItemBuilderConfig(
          source: 'dataContext.requests.search-autocomplete.data.products',
          item: ComponentConfig(
            type: GenericComponentType.text,
            properties: {'valuePath': 'item.name', 'value': ''},
          ),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: renderer.render(
              config,
              buildChild: (c) => TextRenderer().render(
                c,
                buildChild: (_) => const SizedBox.shrink(),
                dataContext: rendererDataContext(),
              ),
              dataContext: rendererDataContext(),
            ),
          ),
        ),
      );

      expect(find.text('لا توجد اقتراحات'), findsNothing);
      expect(find.byType(ListView), findsNothing);
    },
  );
}
