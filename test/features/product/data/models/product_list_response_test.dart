import 'package:flutter_test/flutter_test.dart';
import 'package:sooq_merchant/features/product/data/models/product_list_response.dart';

import '../../support/product_test_utils.dart';

void main() {
  group('ProductListResponse', () {
    test('parses browse envelope with data as list', () {
      final response = ProductListResponse.fromJson(browseProductsEnvelope());

      expect(response.data, hasLength(1));
      expect(response.meta.hasNext, isTrue);
    });

    test('parses search-shaped envelope with data as object', () {
      final envelope = searchEnvelope();
      final stored = {
        'success': envelope['success'],
        'data': envelope['data'],
      };

      final response = ProductListResponse.fromJson(stored);

      expect(response.data, hasLength(1));
      expect(response.meta.page, 0);
    });

    test('returns empty list when data is missing', () {
      final response = ProductListResponse.fromJson({'success': true});

      expect(response.data, isEmpty);
    });
  });
}
