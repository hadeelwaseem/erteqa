import 'package:flutter_test/flutter_test.dart';
import 'package:sooq_merchant/engine/request_ui_state.dart';

void main() {
  group('resolveRequestKey', () {
    test('reads top-level requestKey', () {
      expect(
        resolveRequestKey({'requestKey': 'product-list'}),
        'product-list',
      );
    });

    test('reads props.data.requestKey when top-level absent', () {
      expect(
        resolveRequestKey({
          'data': {'requestKey': 'home-featured-products'},
        }),
        'home-featured-products',
      );
    });

    test('prefers top-level over data.requestKey', () {
      expect(
        resolveRequestKey({
          'requestKey': 'a',
          'data': {'requestKey': 'b'},
        }),
        'a',
      );
    });

    test('returns null when no key', () {
      expect(resolveRequestKey({}), isNull);
      expect(resolveRequestKey(null), isNull);
    });
  });

  group('resolveRequestBoundListPhase', () {
    test('none when requestKey absent', () {
      expect(
        resolveRequestBoundListPhase(
          requestKey: null,
          dataContext: const {},
          itemsEmpty: true,
        ),
        RequestBoundListPhase.none,
      );
    });

    test('loading when key in loadingRequestKeys', () {
      expect(
        resolveRequestBoundListPhase(
          requestKey: 'product-list',
          dataContext: {
            'loadingRequestKeys': {'product-list': true},
            'requests': {
              'product-list': {'success': true, 'data': []},
            },
          },
          itemsEmpty: true,
        ),
        RequestBoundListPhase.loading,
      );
    });

    test('loading when requests entry missing and key is initial page request', () {
      expect(
        resolveRequestBoundListPhase(
          requestKey: 'home-featured-products',
          dataContext: {
            'initialRequestKeys': {'home-featured-products': true},
          },
          itemsEmpty: true,
        ),
        RequestBoundListPhase.loading,
      );
    });

    test('none when requests entry missing for deferred qField request', () {
      expect(
        resolveRequestBoundListPhase(
          requestKey: 'search-autocomplete',
          dataContext: const {},
          itemsEmpty: true,
        ),
        RequestBoundListPhase.none,
      );
    });

    test('error when success is false', () {
      expect(
        resolveRequestBoundListPhase(
          requestKey: 'product-list',
          dataContext: {
            'requests': {
              'product-list': {
                'success': false,
                'message': 'Network error',
                'data': [],
              },
            },
          },
          itemsEmpty: true,
        ),
        RequestBoundListPhase.error,
      );
    });

    test('empty when success and no items', () {
      expect(
        resolveRequestBoundListPhase(
          requestKey: 'product-list',
          dataContext: {
            'requests': {
              'product-list': {'success': true, 'data': []},
            },
          },
          itemsEmpty: true,
        ),
        RequestBoundListPhase.empty,
      );
    });

    test('ready when items present', () {
      expect(
        resolveRequestBoundListPhase(
          requestKey: 'product-list',
          dataContext: {
            'requests': {
              'product-list': {
                'success': true,
                'data': [{'id': '1'}],
              },
            },
          },
          itemsEmpty: false,
        ),
        RequestBoundListPhase.ready,
      );
    });
  });

  group('resolveDisplayMessage', () {
    test('uses prop when set', () {
      expect(
        resolveDisplayMessage(
          prop: 'لا توجد منتجات',
          requestMap: {'message': 'API msg'},
          fallback: kDefaultEmptyMessage,
        ),
        'لا توجد منتجات',
      );
    });

    test('falls back to request message then default', () {
      expect(
        resolveDisplayMessage(
          prop: null,
          requestMap: {'message': 'Server down'},
          fallback: kDefaultErrorMessage,
        ),
        'Server down',
      );
      expect(
        resolveDisplayMessage(
          prop: '  ',
          requestMap: null,
          fallback: kDefaultErrorMessage,
        ),
        kDefaultErrorMessage,
      );
    });
  });
}
