import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sooq_merchant/engine/form/form_state_store.dart';
import 'package:sooq_merchant/engine/visibility/visible_when.dart';

void main() {
  group('VisibleWhenSpec', () {
    test('tryParse returns null for invalid input', () {
      expect(VisibleWhenSpec.tryParse(null), isNull);
      expect(VisibleWhenSpec.tryParse({'field': ''}), isNull);
    });

    test('evaluate isEmpty and nonEmpty for form field', () {
      final formState = FormStateStore();
      formState.updateValue('q', '');
      final specEmpty = VisibleWhenSpec.tryParse({
        'source': 'form',
        'field': 'q',
        'when': 'isEmpty',
      })!;
      final specNonEmpty = VisibleWhenSpec.tryParse({
        'source': 'form',
        'field': 'q',
        'when': 'nonEmpty',
      })!;

      expect(specEmpty.evaluate(formState: formState), isTrue);
      expect(specNonEmpty.evaluate(formState: formState), isFalse);

      formState.updateValue('q', 'phone');
      formState.controllerFor('q').text = 'phone';

      expect(specEmpty.evaluate(formState: formState), isFalse);
      expect(specNonEmpty.evaluate(formState: formState), isTrue);
    });
  });

  testWidgets('wrapWithVisibleWhen hides child when form field is non-empty', (
    tester,
  ) async {
    final formState = FormStateStore();
    final dataContext = {FormStateStore.contextKey: formState};

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: wrapWithVisibleWhen(
            dataContext: dataContext,
            visibleWhenRaw: {
              'source': 'form',
              'field': 'homeSearchQuery',
              'when': 'isEmpty',
            },
            child: const Text('browse'),
          ),
        ),
      ),
    );

    expect(find.text('browse'), findsOneWidget);

    formState.controllerFor('homeSearchQuery').text = 'x';
    await tester.pump();

    expect(find.text('browse'), findsNothing);
  });
}
