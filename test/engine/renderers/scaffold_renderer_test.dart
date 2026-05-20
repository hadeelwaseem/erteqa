import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sooq_merchant/config/component_config.dart';
import 'package:sooq_merchant/core/enums/generic_component_type.dart';
import 'package:sooq_merchant/engine/tree/renderers/scaffold_renderer.dart';
import 'package:sooq_merchant/engine/tree/renderers/text_renderer.dart';

import 'renderer_test_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('scaffold_renderer.dart does not import product feature', () {
    final content = File(
      'lib/engine/tree/renderers/scaffold_renderer.dart',
    ).readAsStringSync();
    expect(content.contains('features/product'), isFalse);
    expect(content.contains('ProductCubit'), isFalse);
  });

  Future<void> pumpScaffold(
    WidgetTester tester, {
    required String pageScroll,
    Map<String, dynamic>? dataContext,
  }) async {    final renderer = ScaffoldRenderer();
    final config = ComponentConfig(
      type: GenericComponentType.scaffold,
      properties: {'pageScroll': pageScroll},
      child: ComponentConfig(
        type: GenericComponentType.text,
        properties: {'value': 'body'},
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: renderer.render(
          config,
          buildChild: (child) => TextRenderer().render(
            child,
            buildChild: (_) => const SizedBox.shrink(),
            dataContext: rendererDataContext(),
          ),
          dataContext: dataContext ?? rendererDataContext(),
        ),
      ),
    );
  }

  testWidgets('pageScroll vertical wraps body in SingleChildScrollView', (
    tester,
  ) async {
    await pumpScaffold(tester, pageScroll: 'vertical');
    expect(find.byType(SingleChildScrollView), findsOneWidget);
    expect(find.byType(Align), findsWidgets);
  });

  testWidgets('pageScroll none omits SingleChildScrollView', (tester) async {
    await pumpScaffold(tester, pageScroll: 'none');
    expect(find.byType(SingleChildScrollView), findsNothing);
    expect(find.byType(Align), findsWidgets);
  });

  testWidgets('loadingMoreRequests shows footer progress indicator', (
    tester,
  ) async {
    await pumpScaffold(
      tester,
      pageScroll: 'vertical',
      dataContext: {
        ...rendererDataContext(),
        'loadingMoreRequests': {'product-list': true},
      },
    );

    expect(find.byType(SingleChildScrollView), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}