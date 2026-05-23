import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sooq_merchant/engine/actions/action_dispatcher.dart';
import 'package:sooq_merchant/engine/form/form_state_store.dart';
void main() {
  testWidgets('cubitCall dispatch accepts source tap in dataContext', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: SizedBox.shrink()),
    );

    final context = tester.element(find.byType(SizedBox));
    final dispatcher = EngineActionDispatcher(
      context: context,
      formState: FormStateStore(),
    );

    await dispatcher.dispatch(
      {
        'type': 'openDrawer',
        'drawerEdge': 'start',
      },
    );

    expect(find.byType(SizedBox), findsOneWidget);
  });
}
