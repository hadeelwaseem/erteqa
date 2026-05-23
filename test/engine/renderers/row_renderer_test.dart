import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sooq_merchant/config/component_config.dart';
import 'package:sooq_merchant/core/enums/generic_component_type.dart';
import 'package:sooq_merchant/engine/tree/renderers/container_renderer.dart';
import 'package:sooq_merchant/engine/tree/renderers/row_renderer.dart';
import 'package:sooq_merchant/engine/tree/renderers/text_renderer.dart';

import 'renderer_test_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<Row> pumpRow(
    WidgetTester tester, {
    required Map<String, dynamic> properties,
    required List<ComponentConfig> children,
    TextDirection ambient = TextDirection.rtl,
  }) async {
    final renderer = RowRenderer();
    final config = ComponentConfig(
      type: GenericComponentType.row,
      properties: properties,
      children: children,
    );

    Widget buildChild(ComponentConfig child) {
      if (child.type == GenericComponentType.container) {
        return ContainerRenderer().render(
          child,
          buildChild: buildChild,
          dataContext: rendererDataContext(),
        );
      }
      return TextRenderer().render(
        child,
        buildChild: (_) => const SizedBox.shrink(),
        dataContext: rendererDataContext(),
      );
    }

    await tester.pumpWidget(
      MaterialApp(
        locale: ambient == TextDirection.rtl
            ? const Locale('ar', 'AE')
            : const Locale('en', 'US'),
        home: Directionality(
          textDirection: ambient,
          child: Scaffold(
            body: SizedBox(
              width: 300,
              child: renderer.render(
                config,
                buildChild: buildChild,
                dataContext: rendererDataContext(),
              ),
            ),
          ),
        ),
      ),
    );

    return tester.widget<Row>(find.byType(Row));
  }

  testWidgets('mainAxis start places first child on visual right in RTL', (
    tester,
  ) async {
    await pumpRow(
      tester,
      properties: const {'mainAxisAlignment': 'start'},
      children: [
        ComponentConfig(
          type: GenericComponentType.text,
          properties: {'value': 'A'},
        ),
        ComponentConfig(
          type: GenericComponentType.text,
          properties: {'value': 'B'},
        ),
      ],
    );

    final a = tester.getTopLeft(find.text('A'));
    final b = tester.getTopLeft(find.text('B'));
    expect(a.dx, greaterThan(b.dx));
  });

  testWidgets('mainAxis end packs children toward visual left in RTL', (
    tester,
  ) async {
    await pumpRow(
      tester,
      properties: const {'mainAxisAlignment': 'end'},
      children: [
        ComponentConfig(
          type: GenericComponentType.text,
          properties: {'value': 'A'},
        ),
        ComponentConfig(
          type: GenericComponentType.text,
          properties: {'value': 'B'},
        ),
      ],
    );

    final a = tester.getTopLeft(find.text('A'));
    final b = tester.getTopLeft(find.text('B'));
    // In RTL, `end` is the left edge; the last child (B) sits leftmost.
    expect(b.dx, lessThan(a.dx));
  });

  testWidgets('mainAxis center groups children in the middle', (tester) async {
    await pumpRow(
      tester,
      properties: const {'mainAxisAlignment': 'center'},
      children: [
        ComponentConfig(
          type: GenericComponentType.text,
          properties: {'value': 'A'},
        ),
        ComponentConfig(
          type: GenericComponentType.text,
          properties: {'value': 'B'},
        ),
      ],
    );

    final rowBox = tester.getSize(find.byType(Row));
    final a = tester.getTopLeft(find.text('A'));
    final b = tester.getTopRight(find.text('B'));
    final groupMid = (a.dx + b.dx) / 2;
    expect(groupMid, closeTo(rowBox.width / 2, 40));
  });

  testWidgets('expand container child is wrapped in Expanded', (tester) async {
    await pumpRow(
      tester,
      properties: const {'mainAxisAlignment': 'start', 'gap': 8},
      children: [
        ComponentConfig(
          type: GenericComponentType.text,
          properties: {'value': 'icon'},
        ),
        ComponentConfig(
          type: GenericComponentType.container,
          properties: const {'expand': true},
          child: ComponentConfig(
            type: GenericComponentType.text,
            properties: {'value': 'hint', 'textAlign': 'right'},
          ),
        ),
      ],
    );

    expect(find.byType(Expanded), findsOneWidget);
  });
}
