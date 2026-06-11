import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sooq_merchant/engine/actions/action_dispatcher.dart';
import 'package:sooq_merchant/engine/page/page_state_store.dart';

void main() {
  testWidgets('setPageState resolves tap values and chains onSuccess', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));

    final context = tester.element(find.byType(SizedBox));
    final pageStateStore = PageStateStore();
    var reloadKey = '';

    pageStateStore.reloadRequest = (key) async {
      reloadKey = key;
    };

    final dispatcher = EngineActionDispatcher(
      context: context,
      pageStateStore: pageStateStore,
    );

    await dispatcher.dispatch(
      {
        'type': 'setPageState',
        'values': {
          'filterTabIndex': {'source': 'tap', 'field': 'index'},
          'orderStatus': {'source': 'tap', 'field': 'status'},
        },
        'onSuccess': {
          'type': 'reloadRequest',
          'requestKey': 'my-orders',
        },
      },
      dataContext: {
        'tap': {'index': 1, 'title': 'مؤكد', 'status': 'CONFIRMED'},
      },
    );

    expect(pageStateStore.values['filterTabIndex'], 1);
    expect(pageStateStore.values['orderStatus'], 'CONFIRMED');
    expect(reloadKey, 'my-orders');
  });

  testWidgets('setPageState removes pageState keys for empty tap values', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));

    final context = tester.element(find.byType(SizedBox));
    final pageStateStore = PageStateStore()
      ..update({'orderStatus': 'CANCELLED'});

    final dispatcher = EngineActionDispatcher(
      context: context,
      pageStateStore: pageStateStore,
    );

    await dispatcher.dispatch(
      {
        'type': 'setPageState',
        'values': {
          'filterTabIndex': {'source': 'tap', 'field': 'index'},
          'orderStatus': {'source': 'tap', 'field': 'status'},
        },
      },
      dataContext: {
        'tap': {'index': 0, 'title': 'الكل', 'status': ''},
      },
    );

    expect(pageStateStore.values['filterTabIndex'], 0);
    expect(pageStateStore.values.containsKey('orderStatus'), isFalse);
  });

  testWidgets('setPageState removes stale keys when tap field is absent', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));

    final context = tester.element(find.byType(SizedBox));
    final pageStateStore = PageStateStore()
      ..update({'productSort': 'createdAt,desc'});

    final dispatcher = EngineActionDispatcher(
      context: context,
      pageStateStore: pageStateStore,
    );

    await dispatcher.dispatch(
      {
        'type': 'setPageState',
        'values': {
          'filterTabIndex': {'source': 'tap', 'field': 'index'},
          'productSort': {'source': 'tap', 'field': 'sort'},
        },
      },
      dataContext: {
        'tap': {'index': 0, 'title': 'الكل', 'sort': ''},
      },
    );

    expect(pageStateStore.values.containsKey('productSort'), isFalse);
  });
}
