import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sooq_merchant/config/component_config.dart';
import 'package:sooq_merchant/core/enums/generic_component_type.dart';
import 'package:sooq_merchant/engine/actions/action_dispatcher.dart';
import 'package:sooq_merchant/engine/tree/renderers/expansion_tile_renderer.dart';

import 'renderer_test_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  ComponentConfig tileConfig({
    Map<String, dynamic>? props,
    List<ComponentConfig>? children,
  }) {
    return ComponentConfig(
      type: GenericComponentType.expansionTile,
      properties: {
        'title': 'سؤال',
        if (props != null) ...props,
      },
      children: children ??
          [
            const ComponentConfig(
              type: GenericComponentType.text,
              properties: {
                'value': 'إجابة',
                'fontSize': 14,
              },
            ),
          ],
    );
  }

  testWidgets('shows title and hides body when collapsed', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ExpansionTileRenderer().render(
            tileConfig(),
            buildChild: (c) => Text(c.properties['value'] as String? ?? ''),
            dataContext: rendererDataContext(),
          ),
        ),
      ),
    );

    expect(find.text('سؤال'), findsOneWidget);
    expect(find.text('إجابة'), findsNothing);
  });

  testWidgets('initiallyExpanded shows body', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ExpansionTileRenderer().render(
            tileConfig(props: {'initiallyExpanded': true}),
            buildChild: (c) => Text(c.properties['value'] as String? ?? ''),
            dataContext: rendererDataContext(),
          ),
        ),
      ),
    );

    expect(find.text('إجابة'), findsOneWidget);
  });

  testWidgets('tap header expands and collapses body', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ExpansionTileRenderer().render(
            tileConfig(),
            buildChild: (c) => Text(c.properties['value'] as String? ?? ''),
            dataContext: rendererDataContext(),
          ),
        ),
      ),
    );

    await tester.tap(find.text('سؤال'));
    await tester.pumpAndSettle();
    expect(find.text('إجابة'), findsOneWidget);

    await tester.tap(find.text('سؤال'));
    await tester.pumpAndSettle();
    expect(find.text('إجابة'), findsNothing);
  });

  testWidgets('renders subtitle and leadingIcon', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ExpansionTileRenderer().render(
            tileConfig(
              props: {
                'subtitle': 'تفاصيل',
                'leadingIcon': 'help_outline',
              },
            ),
            buildChild: (_) => const SizedBox.shrink(),
            dataContext: rendererDataContext(),
          ),
        ),
      ),
    );

    expect(find.text('تفاصيل'), findsOneWidget);
    expect(find.byIcon(Icons.help_outline), findsOneWidget);
  });

  testWidgets('onExpansionChanged merges expanded into tap context', (
    tester,
  ) async {
    Map<String, dynamic>? captured;
    final dataContext = rendererDataContext();

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            dataContext[EngineActionDispatcher.contextKey] =
                _CapturingDispatcher(
                  context: context,
                  onDispatch: (ctx) => captured = ctx,
                );

            return ExpansionTileRenderer().render(
              tileConfig(
                props: {
                  'onExpansionChanged': {
                    'type': 'navigate',
                    'route': '/home',
                  },
                },
              ),
              buildChild: (c) => Text(c.properties['value'] as String? ?? ''),
              dataContext: dataContext,
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('سؤال'));
    await tester.pumpAndSettle();

    expect(captured, isNotNull);
    expect(captured!['tap'], {'expanded': true});
  });

  testWidgets('expanded tile has no trailing Divider by default', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ExpansionTileRenderer().render(
            tileConfig(props: {'initiallyExpanded': true}),
            buildChild: (c) => Text(c.properties['value'] as String? ?? ''),
            dataContext: rendererDataContext(),
          ),
        ),
      ),
    );

    expect(find.byType(Divider), findsNothing);
  });

  testWidgets('showDivider true adds trailing Divider', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ExpansionTileRenderer().render(
            tileConfig(props: {'showDivider': true}),
            buildChild: (c) => Text(c.properties['value'] as String? ?? ''),
            dataContext: rendererDataContext(),
          ),
        ),
      ),
    );

    expect(find.byType(Divider), findsOneWidget);
  });

  testWidgets('empty title returns shrink', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ExpansionTileRenderer().render(
            ComponentConfig(
              type: GenericComponentType.expansionTile,
              properties: {'title': ''},
              children: [
                const ComponentConfig(
                  type: GenericComponentType.text,
                  properties: {'value': 'x'},
                ),
              ],
            ),
            buildChild: (c) => Text(c.properties['value'] as String? ?? ''),
            dataContext: rendererDataContext(),
          ),
        ),
      ),
    );

    expect(find.byType(ExpansionTile), findsNothing);
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
