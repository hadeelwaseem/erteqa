import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sooq_merchant/config/component_config.dart';
import 'package:sooq_merchant/core/enums/generic_component_type.dart';
import 'package:sooq_merchant/engine/form/form_state_store.dart';
import 'package:sooq_merchant/engine/tree/renderers/form_renderer.dart';
import 'package:sooq_merchant/engine/tree/renderers/otp_input_renderer.dart';

import 'renderer_test_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpOtpForm(
    WidgetTester tester, {
    required FormStateStore formState,
  }) async {
    final formConfig = ComponentConfig(
      type: GenericComponentType.form,
      properties: const {'formId': 'otp-form'},
      child: ComponentConfig(
        type: GenericComponentType.otpInput,
        properties: const {
          'fieldId': 'otpCode',
          'length': 6,
          'validateRequired': true,
          'validateMinLength': 6,
          'validateMaxLength': 6,
        },
      ),
    );

    final dataContext = formRendererDataContext();
    dataContext[FormStateStore.contextKey] = formState;

    await tester.pumpWidget(
      MaterialApp(
        home: FormRenderer().render(
          formConfig,
          buildChild: (child) => OtpInputRenderer().render(
            child,
            buildChild: (_) => const SizedBox.shrink(),
            dataContext: dataContext,
          ),
          dataContext: dataContext,
        ),
      ),
    );
  }

  testWidgets('renders six digit boxes', (tester) async {
    await pumpOtpForm(tester, formState: FormStateStore());
    expect(find.byType(TextFormField), findsNWidgets(6));
  });

  testWidgets('typing updates FormStateStore otpCode', (tester) async {
    final formState = FormStateStore();
    await pumpOtpForm(tester, formState: formState);

    await tester.enterText(find.byType(TextFormField).at(0), '1');
    await tester.enterText(find.byType(TextFormField).at(1), '2');
    await tester.enterText(find.byType(TextFormField).at(2), '3');
    await tester.pump();

    expect(formState.valueFor('otpCode'), '123');
  });

  testWidgets('form validation fails until six digits', (tester) async {
    final formState = FormStateStore();
    await pumpOtpForm(tester, formState: formState);

    await tester.enterText(find.byType(TextFormField).at(0), '1');
    await tester.pump();

    expect(formState.validate('otp-form'), isFalse);
    await tester.pump();
    expect(find.textContaining('أحرف'), findsOneWidget);

    for (var i = 0; i < 6; i++) {
      await tester.enterText(
        find.byType(TextFormField).at(i),
        '${i + 1}',
      );
    }
    await tester.pump();

    expect(formState.valueFor('otpCode'), '123456');
    expect(formState.validate('otp-form'), isTrue);
  });
}
