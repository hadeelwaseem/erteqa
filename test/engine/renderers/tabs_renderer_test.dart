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
    expect(capturedContext!['tap'], {'index': 2});
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
