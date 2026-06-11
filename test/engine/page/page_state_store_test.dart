import 'package:flutter_test/flutter_test.dart';
import 'package:sooq_merchant/engine/page/page_state_store.dart';

void main() {
  test('update merges values and notifies onChanged', () {
    var notifyCount = 0;
    final store = PageStateStore();
    store.onChanged = () => notifyCount++;

    store.update({'filterTabIndex': 1, 'orderStatus': 'CONFIRMED'});

    expect(store.values['filterTabIndex'], 1);
    expect(store.values['orderStatus'], 'CONFIRMED');
    expect(notifyCount, 1);
  });

  test('update removes keys when value is null or empty string', () {
    final store = PageStateStore()..update({'orderStatus': 'CONFIRMED'});

    store.update({'orderStatus': ''});

    expect(store.values.containsKey('orderStatus'), isFalse);
  });

  test('clear removes all values and notifies', () {
    var notified = false;
    final store = PageStateStore()
      ..update({'filterTabIndex': 2})
      ..onChanged = () => notified = true;

    store.clear();

    expect(store.values, isEmpty);
    expect(notified, isTrue);
  });

  test('snapshot returns defensive copy', () {
    final store = PageStateStore()..update({'a': 1});
    final snap = store.snapshot();
    snap['a'] = 2;
    expect(store.values['a'], 1);
  });
}
