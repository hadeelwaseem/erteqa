import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sooq_merchant/config/component_config.dart';
import 'package:sooq_merchant/core/enums/generic_component_type.dart';
import 'package:sooq_merchant/engine/tree/renderers/contact_button_renderer.dart';

import 'renderer_test_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('whatsapp channel uses green background and row layout', (tester) async {
    final renderer = ContactButtonRenderer();
    final config = ComponentConfig(
      type: GenericComponentType.contactButton,
      properties: {
        'channel': 'whatsapp',
        'label': 'واتساب',
        'target': '963935237452',
        'onTap': () {},
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

    expect(find.byType(Row), findsOneWidget);
    expect(find.text('واتساب'), findsOneWidget);
    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNotNull);
    final bg = button.style?.backgroundColor?.resolve({});
    expect(bg, const Color(0xFF25D366));
  });

  testWidgets('disabled when target empty', (tester) async {
    final renderer = ContactButtonRenderer();
    final config = ComponentConfig(
      type: GenericComponentType.contactButton,
      properties: {
        'channel': 'tel',
        'label': 'اتصل بنا',
        'onTap': () {},
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

    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);
  });

  testWidgets('targetPath resolves from dataContext', (tester) async {
    var tapped = false;
    final renderer = ContactButtonRenderer();
    final config = ComponentConfig(
      type: GenericComponentType.contactButton,
      properties: {
        'channel': 'tel',
        'label': 'اتصل بنا',
        'targetPath': 'app.supportPhone',
        'onTap': () => tapped = true,
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
              'app': {'supportPhone': '963111222333'},
            },
          ),
        ),
      ),
    );

    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNotNull);
    button.onPressed?.call();
    expect(tapped, isTrue);
  });
}
