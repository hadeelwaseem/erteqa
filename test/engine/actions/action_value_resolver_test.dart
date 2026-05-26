import 'package:flutter_test/flutter_test.dart';
import 'package:sooq_merchant/engine/actions/action_value_resolver.dart';
import 'package:sooq_merchant/engine/form/form_state_store.dart';

void main() {
  group('ActionValueResolver', () {
    test('resolves plain string', () {
      final resolver = ActionValueResolver();
      expect(resolver.resolveString('963935237452'), '963935237452');
    });

    test('resolves app source from dataContext', () {
      final resolver = ActionValueResolver();
      expect(
        resolver.resolveString(
          {'source': 'app', 'field': 'supportWhatsApp'},
          dataContext: {
            'app': {'supportWhatsApp': '963935237452'},
          },
        ),
        '963935237452',
      );
    });

    test('resolves form source', () {
      final formState = FormStateStore();
      formState.updateValue('phone', '963900000000');
      final resolver = ActionValueResolver(formState: formState);
      expect(
        resolver.resolveString(
          {'source': 'form', 'field': 'phone'},
        ),
        '963900000000',
      );
    });
  });
}
