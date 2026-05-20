import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sooq_merchant/config/component_config.dart';
import 'package:sooq_merchant/core/enums/generic_component_type.dart';
import 'package:sooq_merchant/engine/form/form_state_store.dart';
import 'package:sooq_merchant/engine/tree/renderers/form_renderer.dart';
import 'package:sooq_merchant/engine/tree/renderers/text_renderer.dart';

import 'renderer_test_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('renders Form with key from formId', (tester) async {
    final store = FormStateStore();
    final renderer = FormRenderer();
    final config = ComponentConfig(
      type: GenericComponentType.form,
      properties: {'formId': 'otp-request-form'},
      child: ComponentConfig(
        type: GenericComponentType.text,
        properties: {'value': 'child'},
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: renderer.render(
            config,
            buildChild: (child) => TextRenderer().render(
              child,
              buildChild: (_) => const SizedBox.shrink(),
              dataContext: formRendererDataContext(),
            ),
            dataContext: {
              ...formRendererDataContext(),
              FormStateStore.contextKey: store,
            },
          ),
        ),
      ),
    );

    expect(find.byType(Form), findsOneWidget);
    final form = tester.widget<Form>(find.byType(Form));
    expect(form.key, store.formKeyFor('otp-request-form'));
  });

  testWidgets('children path inserts spacing between fields', (tester) async {
    final store = FormStateStore();
    final renderer = FormRenderer();
    final config = ComponentConfig(
      type: GenericComponentType.form,
      properties: {'formId': 'f'},
      children: [
        ComponentConfig(
          type: GenericComponentType.text,
          properties: {'value': 'a'},
        ),
        ComponentConfig(
          type: GenericComponentType.text,
          properties: {'value': 'b'},
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: renderer.render(
            config,
            buildChild: (child) => TextRenderer().render(
              child,
              buildChild: (_) => const SizedBox.shrink(),
              dataContext: formRendererDataContext(),
            ),
            dataContext: {
              ...formRendererDataContext(),
              FormStateStore.contextKey: store,
            },
          ),
        ),
      ),
    );

    final column = tester.widget<Column>(find.byType(Column));
    expect(column.children.length, 3);
    expect(column.children[1], isA<SizedBox>());
    final gap = column.children[1] as SizedBox;
    expect(gap.height, 10);
  });

  testWidgets('autovalidateMode onUserInteraction passed to Form', (tester) async {
    final store = FormStateStore();
    final renderer = FormRenderer();
    final config = ComponentConfig(
      type: GenericComponentType.form,
      properties: {
        'formId': 'f',
        'autovalidateMode': 'onUserInteraction',
      },
      child: ComponentConfig(
        type: GenericComponentType.text,
        properties: {'value': 'x'},
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: renderer.render(
            config,
            buildChild: (child) => TextRenderer().render(
              child,
              buildChild: (_) => const SizedBox.shrink(),
              dataContext: formRendererDataContext(),
            ),
            dataContext: {
              ...formRendererDataContext(),
              FormStateStore.contextKey: store,
            },
          ),
        ),
      ),
    );

    final form = tester.widget<Form>(find.byType(Form));
    expect(form.autovalidateMode, AutovalidateMode.onUserInteraction);
  });
}
