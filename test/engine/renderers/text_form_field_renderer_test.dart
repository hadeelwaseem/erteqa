import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sooq_merchant/config/component_config.dart';
import 'package:sooq_merchant/core/enums/generic_component_type.dart';
import 'package:sooq_merchant/engine/form/form_state_store.dart';
import 'package:sooq_merchant/engine/tree/renderers/text_form_field_renderer.dart';

import 'renderer_test_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('required empty field shows Arabic requiredMessage', (tester) async {
    final renderer = TextFormFieldRenderer();
    final store = FormStateStore();
    final config = ComponentConfig(
      type: GenericComponentType.textFormField,
      properties: {
        'id': 'phone',
        'validateRequired': true,
      },
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Form(
            key: store.formKeyFor('test-form'),
            child: renderer.render(
              config,
              buildChild: (_) => const SizedBox.shrink(),
              dataContext: {
                ...formRendererDataContext(),
                FormStateStore.contextKey: store,
              },
            ),
          ),
        ),
      ),
    );

    final state = store.formKeyFor('test-form').currentState!;
    expect(state.validate(), isFalse);
    await tester.pump();

    expect(find.text('هذا الحقل مطلوب'), findsOneWidget);
  });

  testWidgets('static error prop ignored when validator is active', (tester) async {
    final renderer = TextFormFieldRenderer();
    final store = FormStateStore();
    final config = ComponentConfig(
      type: GenericComponentType.textFormField,
      properties: {
        'id': 'phone',
        'validateRequired': true,
        'error': 'Static error from JSON',
      },
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Form(
            key: store.formKeyFor('f'),
            child: renderer.render(
              config,
              buildChild: (_) => const SizedBox.shrink(),
              dataContext: {
                ...formRendererDataContext(),
                FormStateStore.contextKey: store,
              },
            ),
          ),
        ),
      ),
    );

    store.formKeyFor('f').currentState!.validate();
    await tester.pump();

    expect(find.text('Static error from JSON'), findsNothing);
    expect(find.text('هذا الحقل مطلوب'), findsOneWidget);
  });

  testWidgets('theme fill applied when props omit color', (tester) async {
    final renderer = TextFormFieldRenderer();
    final store = FormStateStore();
    final config = ComponentConfig(
      type: GenericComponentType.textFormField,
      properties: {'id': 'x', 'label': 'Label'},
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Form(
            key: store.formKeyFor('f'),
            child: renderer.render(
              config,
              buildChild: (_) => const SizedBox.shrink(),
              dataContext: {
                ...formRendererDataContext(),
                FormStateStore.contextKey: store,
              },
            ),
          ),
        ),
      ),
    );

    final inputDecorator = tester.widget<InputDecorator>(find.byType(InputDecorator));
    expect(inputDecorator.decoration.filled, isTrue);
    expect(inputDecorator.decoration.fillColor, const Color(0xFFF8FAFC));
  });

  testWidgets('prefix icon meets minimum tap target', (tester) async {
    final renderer = TextFormFieldRenderer();
    final store = FormStateStore();
    final config = ComponentConfig(
      type: GenericComponentType.textFormField,
      properties: {
        'id': 'x',
        'prefixIcon': 'phone',
      },
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Form(
            key: store.formKeyFor('f'),
            child: renderer.render(
              config,
              buildChild: (_) => const SizedBox.shrink(),
              dataContext: {
                ...formRendererDataContext(),
                FormStateStore.contextKey: store,
              },
            ),
          ),
        ),
      ),
    );

    final sizedBox = tester.widget<SizedBox>(
      find.descendant(
        of: find.byType(TextFormField),
        matching: find.byType(SizedBox),
      ).first,
    );
    expect(sizedBox.width, 48);
    expect(sizedBox.height, 48);
  });

  testWidgets('Semantics exposes label and hint', (tester) async {
    final renderer = TextFormFieldRenderer();
    final store = FormStateStore();
    final config = ComponentConfig(
      type: GenericComponentType.textFormField,
      properties: {
        'id': 'phone',
        'label': 'رقم الجوال',
        'hint': '05xxxxxxxx',
      },
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Form(
            key: store.formKeyFor('f'),
            child: renderer.render(
              config,
              buildChild: (_) => const SizedBox.shrink(),
              dataContext: {
                ...formRendererDataContext(),
                FormStateStore.contextKey: store,
              },
            ),
          ),
        ),
      ),
    );

    final semantics = tester.getSemantics(find.byType(TextFormField));
    expect(semantics.label, 'رقم الجوال');
    expect(semantics.hasFlag(SemanticsFlag.isTextField), isTrue);
  });

  testWidgets('validation error text shown after validate', (tester) async {
    final renderer = TextFormFieldRenderer();
    final store = FormStateStore();
    final config = ComponentConfig(
      type: GenericComponentType.textFormField,
      properties: {
        'id': 'phone',
        'label': 'رقم الجوال',
        'validateRequired': true,
      },
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Form(
            key: store.formKeyFor('f'),
            child: renderer.render(
              config,
              buildChild: (_) => const SizedBox.shrink(),
              dataContext: {
                ...formRendererDataContext(),
                FormStateStore.contextKey: store,
              },
            ),
          ),
        ),
      ),
    );

    store.formKeyFor('f').currentState!.validate();
    await tester.pump();

    expect(find.text('هذا الحقل مطلوب'), findsOneWidget);
  });
}
