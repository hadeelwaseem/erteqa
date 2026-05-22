import 'package:flutter_test/flutter_test.dart';
import 'package:sooq_merchant/core/navigation/app_navigation.dart';

void main() {
  group('parseNavigationType', () {
    test('defaults to clearStack for null and empty', () {
      expect(parseNavigationType(null), NavigationType.clearStack);
      expect(parseNavigationType(''), NavigationType.clearStack);
      expect(parseNavigationType('   '), NavigationType.clearStack);
    });

    test('recognizes push aliases', () {
      expect(parseNavigationType('push'), NavigationType.push);
      expect(parseNavigationType('stack'), NavigationType.push);
      expect(parseNavigationType(' PUSH '), NavigationType.push);
    });

    test('recognizes clearStack aliases', () {
      expect(parseNavigationType('clear_stack'), NavigationType.clearStack);
      expect(parseNavigationType('clearstack'), NavigationType.clearStack);
      expect(parseNavigationType('reset'), NavigationType.clearStack);
      expect(parseNavigationType('go'), NavigationType.clearStack);
      expect(parseNavigationType('Clear_Stack'), NavigationType.clearStack);
    });

    test('unknown values default to clearStack', () {
      expect(parseNavigationType('replace'), NavigationType.clearStack);
      expect(parseNavigationType('pop'), NavigationType.clearStack);
    });
  });
}
