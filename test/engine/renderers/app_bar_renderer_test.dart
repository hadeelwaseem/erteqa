import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sooq_merchant/config/component_config.dart';
import 'package:sooq_merchant/core/enums/generic_component_type.dart';
import 'package:sooq_merchant/engine/tree/renderers/app_bar_renderer.dart';

import 'renderer_test_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('foregroundColor applies to title text', (tester) async {
    final renderer = AppBarRenderer();
    final config = ComponentConfig(
      type: GenericComponentType.appBar,
      properties: {
        'title': 'Test',
        'backgroundColor': '#FFFFFF',
        'foregroundColor': '#FF0000',
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

    final titleText = tester.widget<Text>(find.text('Test'));
    expect(titleText.style?.color, const Color(0xFFFF0000));
  });

  testWidgets('back IconButton has minimum 48x48 tap target when can pop',
      (tester) async {
    final renderer = AppBarRenderer();
    final config = ComponentConfig(
      type: GenericComponentType.appBar,
      properties: {'title': 'Back test'},
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => Scaffold(
                      body: renderer.render(
                        config,
                        buildChild: (_) => const SizedBox.shrink(),
                        dataContext: rendererDataContext(),
                      ),
                    ),
                  ),
                );
              },
              child: const Text('push'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('push'));
    await tester.pumpAndSettle();

    final iconButton = tester.widget<IconButton>(find.byType(IconButton));
    expect(iconButton.constraints?.minWidth, 48);
    expect(iconButton.constraints?.minHeight, 48);
  });
}
