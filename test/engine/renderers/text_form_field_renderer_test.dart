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

  testWidgets('phone keyboard defaults to LTR in RTL app', (tester) async {
    final renderer = TextFormFieldRenderer();
    final store = FormStateStore();
    final config = ComponentConfig(
      type: GenericComponentType.textFormField,
      properties: {
        'id': 'phone',
        'label': 'رقم الجوال',
        'keyboardType': 'phone',
      },
    );

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.rtl,
        child: MaterialApp(
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
      ),
    );

    final editable = tester.widget<EditableText>(
      find.descendant(
        of: find.byType(TextFormField),
        matching: find.byType(EditableText),
      ),
    );
    expect(editable.textDirection, TextDirection.ltr);
    expect(
      editable.textAlign,
      anyOf(TextAlign.left, TextAlign.start),
    );
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

  testWidgets('auth login style renders outline border and fill', (tester) async {
    final renderer = TextFormFieldRenderer();
    final store = FormStateStore();
    final config = ComponentConfig(
      type: GenericComponentType.textFormField,
      properties: {
        'id': 'phone',
        'label': 'رقم الجوال',
        'hint': '+963911000111',
        'keyboardType': 'phone',
        'textAlign': 'right',
        'validateRequired': true,
        'validatePhone': true,
        'requiredMessage': 'هذا الحقل مطلوب',
        'padding': {'left': 12, 'right': 12, 'top': 6, 'bottom': 6},
        'color': '#F8FAFC',
        'borderRadius': 10,
        'border': {'width': 1, 'color': '#E2E8F0'},
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

    final decorator = tester.widget<InputDecorator>(find.byType(InputDecorator));
    expect(decorator.decoration.filled, isTrue);
    expect(decorator.decoration.fillColor, const Color(0xFFF8FAFC));
    final enabled = decorator.decoration.enabledBorder! as OutlineInputBorder;
    expect(enabled.borderRadius, BorderRadius.circular(10));
    expect(enabled.borderSide.color, const Color(0xFFE2E8F0));
    expect(enabled.borderSide.width, 1);
    expect(decorator.decoration.contentPadding, const EdgeInsets.fromLTRB(12, 6, 12, 6));
    expect(find.text('رقم الجوال'), findsOneWidget);
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

  testWidgets('clearable shows suffix clear icon and clears field on tap', (
    tester,
  ) async {
    final renderer = TextFormFieldRenderer();
    final store = FormStateStore();
    store.controllerFor('homeSearchQuery').text = 'phone';
    store.updateValue('homeSearchQuery', 'phone');
    final config = ComponentConfig(
      type: GenericComponentType.textFormField,
      properties: {
        'id': 'homeSearchQuery',
        'clearable': true,
        'clearIcon': 'close',
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

    expect(find.byIcon(Icons.close), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pump();

    expect(store.controllerFor('homeSearchQuery').text, isEmpty);
    expect(store.valueFor('homeSearchQuery'), '');
    expect(find.byIcon(Icons.close), findsNothing);
  });
}
