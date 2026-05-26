import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sooq_merchant/config/component_config.dart';
import 'package:sooq_merchant/core/enums/generic_component_type.dart';
import 'package:sooq_merchant/engine/actions/action_dispatcher.dart';
import 'package:sooq_merchant/engine/form/form_state_store.dart';
import 'package:sooq_merchant/engine/tree/renderers/dropdown_renderer.dart';

import 'renderer_test_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  ComponentConfig dropdownConfig({
    Map<String, dynamic>? extra,
    Map<String, dynamic>? data,
  }) {
    return ComponentConfig(
      type: GenericComponentType.dropdown,
      properties: {
        'id': 'sort',
        'label': 'ترتيب',
        'value': 'relevance',
        'data': data ??
            {
              'items': [
                {'label': 'الأكثر صلة', 'value': 'relevance', 'index': 0},
                {'label': 'السعر', 'value': 'price_asc', 'index': 1},
              ],
            },
        if (extra != null) ...extra,
      },
    );
  }

  testWidgets('renders label and selected item', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DropdownRenderer().render(
            dropdownConfig(),
            buildChild: (_) => const SizedBox.shrink(),
            dataContext: rendererDataContext(),
          ),
        ),
      ),
    );

    expect(find.text('ترتيب'), findsOneWidget);
    expect(find.text('الأكثر صلة'), findsOneWidget);
  });

  testWidgets('required empty shows Arabic requiredMessage', (tester) async {
    final store = FormStateStore();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Form(
            key: store.formKeyFor('f'),
            child: DropdownRenderer().render(
              ComponentConfig(
                type: GenericComponentType.dropdown,
                properties: {
                  'id': 'country',
                  'validateRequired': true,
                  'data': {
                    'items': [
                      {'label': 'سوريا', 'value': 'sy'},
                    ],
                  },
                },
              ),
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

  testWidgets('tap merges value and index into dataContext', (tester) async {
    Map<String, dynamic>? captured;
    final dataContext = rendererDataContext();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              dataContext[EngineActionDispatcher.contextKey] =
                  _CapturingDispatcher(
                    context: context,
                    onDispatch: (ctx) => captured = ctx,
                  );

              return DropdownRenderer().render(
                dropdownConfig(
                  extra: {
                    'tap': {'type': 'navigate', 'route': '/home'},
                  },
                ),
                buildChild: (_) => const SizedBox.shrink(),
                dataContext: dataContext,
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.byType(DropdownButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('السعر').last);
    await tester.pumpAndSettle();

    expect(captured, isNotNull);
    expect(captured!['tap'], {
      'value': 'price_asc',
      'index': 1,
      'label': 'السعر',
    });
  });

  testWidgets('valuePath resolves initial selection', (tester) async {
    final dataContext = {
      ...rendererDataContext(),
      'selectedSort': 'price_asc',
    };

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DropdownRenderer().render(
            ComponentConfig(
              type: GenericComponentType.dropdown,
              properties: {
                'id': 'sort',
                'label': 'ترتيب',
                'valuePath': 'selectedSort',
                'data': {
                  'items': [
                    {'label': 'الأكثر صلة', 'value': 'relevance', 'index': 0},
                    {'label': 'السعر', 'value': 'price_asc', 'index': 1},
                  ],
                },
              },
            ),
            buildChild: (_) => const SizedBox.shrink(),
            dataContext: dataContext,
          ),
        ),
      ),
    );

    expect(find.text('السعر'), findsOneWidget);
  });

  testWidgets('itemsPath resolves dynamic items', (tester) async {
    final dataContext = {
      ...rendererDataContext(),
      'requests': {
        'cats': {
          'data': [
            {'name': 'إلكترونيات', 'slug': 'electronics'},
            {'name': 'أزياء', 'slug': 'fashion'},
          ],
        },
      },
    };

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DropdownRenderer().render(
            ComponentConfig(
              type: GenericComponentType.dropdown,
              properties: {
                'id': 'category',
                'hint': 'التصنيف',
                'itemsPath': 'dataContext.requests.cats.data',
              },
            ),
            buildChild: (_) => const SizedBox.shrink(),
            dataContext: dataContext,
          ),
        ),
      ),
    );

    await tester.tap(find.byType(DropdownButton<String>));
    await tester.pumpAndSettle();
    expect(find.text('إلكترونيات'), findsOneWidget);
  });

  testWidgets('empty items shows empty hint and is disabled', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DropdownRenderer().render(
            ComponentConfig(
              type: GenericComponentType.dropdown,
              properties: {
                'id': 'empty',
                'hint': 'اختر',
                'emptyHint': 'لا خيارات',
                'data': {'items': []},
              },
            ),
            buildChild: (_) => const SizedBox.shrink(),
            dataContext: rendererDataContext(),
          ),
        ),
      ),
    );

    expect(find.text('لا خيارات'), findsWidgets);
    final dropdown = tester.widget<DropdownButton<String>>(
      find.byType(DropdownButton<String>),
    );
    expect(dropdown.onChanged, isNull);
  });

  testWidgets('renders in RTL without overflow', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: SizedBox(
              width: 200,
              child: DropdownRenderer().render(
                dropdownConfig(extra: {'isExpanded': true}),
                buildChild: (_) => const SizedBox.shrink(),
                dataContext: rendererDataContext(),
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
  });

  testWidgets('hint-only dropdown in row does not throw layout error', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('نتائج البحث'),
              DropdownRenderer().render(
                ComponentConfig(
                  type: GenericComponentType.dropdown,
                  properties: {
                    'id': 'searchSort',
                    'hint': 'ترتيب',
                    'value': 'relevance',
                    'data': {
                      'items': [
                        {'label': 'الأكثر صلة', 'value': 'relevance'},
                        {'label': 'السعر', 'value': 'price_asc'},
                      ],
                    },
                  },
                ),
                buildChild: (_) => const SizedBox.shrink(),
                dataContext: rendererDataContext(),
              ),
            ],
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(DropdownButton<String>), findsOneWidget);
    expect(find.byType(InputDecorator), findsNothing);
  });

  testWidgets('labeled dropdown uses compact dense height', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DropdownRenderer().render(
            ComponentConfig(
              type: GenericComponentType.dropdown,
              properties: {
                'id': 'appLanguage',
                'label': 'اللغة',
                'value': 'ar',
                'isExpanded': true,
                'isDense': true,
                'padding': {'left': 12, 'right': 12, 'top': 4, 'bottom': 4},
                'data': {
                  'items': [
                    {'label': 'العربية', 'value': 'ar'},
                    {'label': 'English', 'value': 'en'},
                  ],
                },
              },
            ),
            buildChild: (_) => const SizedBox.shrink(),
            dataContext: rendererDataContext(),
          ),
        ),
      ),
    );

    final size = tester.getSize(find.byType(DropdownButtonFormField<String>));
    expect(size.height, lessThan(72));
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
