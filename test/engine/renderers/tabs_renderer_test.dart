import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sooq_merchant/config/component_config.dart';
import 'package:sooq_merchant/core/enums/generic_component_type.dart';
import 'package:sooq_merchant/engine/actions/action_dispatcher.dart';
import 'package:sooq_merchant/engine/tree/renderers/tabs_renderer.dart';

import 'renderer_test_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('renders tab labels with active underline', (tester) async {
    final renderer = TabsRenderer();
    final config = ComponentConfig(
      type: GenericComponentType.tabs,
      properties: {
        'selectedIndex': 1,
        'data': {
          'items': [
            {'title': 'All', 'index': 0},
            {'title': 'Sale', 'index': 1},
          ],
        },
      },
    );

    await tester.pumpWidget(
      MaterialApp(
        home: renderer.render(
          config,
          buildChild: (_) => const SizedBox.shrink(),
          dataContext: rendererDataContext(),
        ),
      ),
    );

    expect(find.text('All'), findsOneWidget);
    expect(find.text('Sale'), findsOneWidget);
  });

  testWidgets('tab tap merges index into dataContext for dispatch', (
    tester,
  ) async {
    Map<String, dynamic>? capturedContext;
    final dataContext = rendererDataContext();

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            dataContext[EngineActionDispatcher.contextKey] =
                _CapturingDispatcher(
                  context: context,
                  onDispatch: (ctx) => capturedContext = ctx,
                );

            return TabsRenderer().render(
              ComponentConfig(
                type: GenericComponentType.tabs,
                properties: {
                  'selectedIndex': 0,
                  'data': {
                    'items': [
                      {'title': 'A', 'index': 0},
                      {'title': 'B', 'index': 2},
                    ],
                  },
                  'tap': {
                    'type': 'navigate',
                    'route': '/home',
                  },
                },
              ),
              buildChild: (_) => const SizedBox.shrink(),
              dataContext: dataContext,
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('B'));
    await tester.pump();

    expect(capturedContext, isNotNull);
    expect(capturedContext!['tap'], {'title': 'B', 'index': 2});
  });

  testWidgets('tab tap carries custom metadata from item JSON', (
    tester,
  ) async {
    Map<String, dynamic>? capturedContext;
    final dataContext = rendererDataContext();

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            dataContext[EngineActionDispatcher.contextKey] =
                _CapturingDispatcher(
                  context: context,
                  onDispatch: (ctx) => capturedContext = ctx,
                );

            return TabsRenderer().render(
              ComponentConfig(
                type: GenericComponentType.tabs,
                properties: {
                  'data': {
                    'items': [
                      {
                        'title': 'All',
                        'index': 0,
                        'status': '',
                      },
                      {
                        'title': 'Confirmed',
                        'index': 1,
                        'status': 'CONFIRMED',
                      },
                    ],
                  },
                  'tap': {'type': 'setPageState', 'values': {}},
                },
              ),
              buildChild: (_) => const SizedBox.shrink(),
              dataContext: dataContext,
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Confirmed'));
    await tester.pump();

    expect(capturedContext!['tap'], {
      'title': 'Confirmed',
      'index': 1,
      'status': 'CONFIRMED',
    });
  });

  testWidgets('selectedIndexPath reads from dataContext', (tester) async {
    final dataContext = {
      ...rendererDataContext(),
      'filterTabIndex': 2,
    };

    await tester.pumpWidget(
      MaterialApp(
        home: TabsRenderer().render(
          ComponentConfig(
            type: GenericComponentType.tabs,
            properties: {
              'selectedIndex': 0,
              'selectedIndexPath': 'filterTabIndex',
              'data': {
                'items': [
                  {'title': 'T0', 'index': 0},
                  {'title': 'T2', 'index': 2},
                ],
              },
            },
          ),
          buildChild: (_) => const SizedBox.shrink(),
          dataContext: dataContext,
        ),
      ),
    );

    final saleTab = tester.widget<Container>(
      find.ancestor(
        of: find.text('T2'),
        matching: find.byType(Container),
      ).first,
    );
    final border = saleTab.decoration! as BoxDecoration;
    expect(border.border?.bottom.color, isNot(equals(Colors.transparent)));
  });

  testWidgets('itemsPath with staticItems prefix builds dynamic tab chips', (
    tester,
  ) async {
    final dataContext = {
      ...rendererDataContext(),
      'requests': {
        'category-tree': {
          'data': [
            {'name': 'Electronics', 'slug': 'electronics'},
            {'name': 'Fashion', 'slug': 'fashion'},
          ],
        },
      },
    };

    await tester.pumpWidget(
      MaterialApp(
        home: TabsRenderer().render(
          ComponentConfig(
            type: GenericComponentType.tabs,
            properties: {
              'itemsPath': 'dataContext.requests.category-tree.data',
              'itemLabelPath': 'name',
              'itemValuePath': 'slug',
              'data': {
                'staticItems': [
                  {'title': 'All', 'index': 0, 'slug': ''},
                ],
              },
            },
          ),
          buildChild: (_) => const SizedBox.shrink(),
          dataContext: dataContext,
        ),
      ),
    );

    expect(find.text('All'), findsOneWidget);
    expect(find.text('Electronics'), findsOneWidget);
    expect(find.text('Fashion'), findsOneWidget);
  });

  testWidgets('dynamic tab tap includes slug metadata', (tester) async {
    Map<String, dynamic>? capturedContext;
    final dataContext = {
      ...rendererDataContext(),
      'requests': {
        'category-tree': {
          'data': [
            {'name': 'Electronics', 'slug': 'electronics'},
          ],
        },
      },
    };

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            dataContext[EngineActionDispatcher.contextKey] =
                _CapturingDispatcher(
                  context: context,
                  onDispatch: (ctx) => capturedContext = ctx,
                );

            return TabsRenderer().render(
              ComponentConfig(
                type: GenericComponentType.tabs,
                properties: {
                  'itemsPath': 'dataContext.requests.category-tree.data',
                  'itemLabelPath': 'name',
                  'itemValuePath': 'slug',
                  'data': {
                    'staticItems': [
                      {'title': 'All', 'index': 0, 'slug': ''},
                    ],
                  },
                  'tap': {'type': 'setPageState', 'values': {}},
                },
              ),
              buildChild: (_) => const SizedBox.shrink(),
              dataContext: dataContext,
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Electronics'));
    await tester.pump();

    expect(capturedContext!['tap']['slug'], 'electronics');
    expect(capturedContext!['tap']['index'], 1);
  });

  testWidgets('flattenItems leaves expands nested categories', (tester) async {
    final dataContext = {
      ...rendererDataContext(),
      'requests': {
        'category-tree': {
          'data': [
            {
              'name': 'Food',
              'categoryId': 'food',
              'children': [
                {'name': 'Snacks', 'categoryId': 'snacks'},
              ],
            },
          ],
        },
      },
    };

    await tester.pumpWidget(
      MaterialApp(
        home: TabsRenderer().render(
          ComponentConfig(
            type: GenericComponentType.tabs,
            properties: {
              'itemsPath': 'dataContext.requests.category-tree.data',
              'itemLabelPath': 'name',
              'itemValuePath': 'categoryId',
              'flattenItems': 'leaves',
              'data': {
                'staticItems': [
                  {'title': 'All', 'index': 0, 'categoryId': ''},
                ],
              },
            },
          ),
          buildChild: (_) => const SizedBox.shrink(),
          dataContext: dataContext,
        ),
      ),
    );

    expect(find.text('All'), findsOneWidget);
    expect(find.text('Food'), findsNothing);
    expect(find.text('Snacks'), findsOneWidget);
  });
}

class _CapturingDispatcher extends EngineActionDispatcher {
  _CapturingDispatcher({
    required super.context,
    required this.onDispatch,
  });

  final void Function(Map<String, dynamic>? dataContext) onDispatch;

  @override
  Future<void> dispatch(
    Map<String, dynamic> action, {
    String? value,
    String? fieldId,
    Map<String, dynamic>? dataContext,
  }) async {
    onDispatch(dataContext);
  }
}
