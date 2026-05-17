import 'package:flutter_test/flutter_test.dart';
import 'package:sooq_merchant/features/product/data/models/product_search_result.dart';

import '../../support/product_test_utils.dart';

void main() {
  group('ProductSearchResult', () {
    test('parses empty products with suggestions and popularProducts', () {
      final result = ProductSearchResult.fromEnvelopeData(
        (        searchEnvelope(
          products: const [],
          suggestions: const ['phone cases', 'phone chargers'],
          popularProducts: [sampleProductItem(titleEn: 'Popular Phone')],
        )['data'] as Map<String, dynamic>),
      );

      expect(result.products, isEmpty);
      expect(result.suggestions, hasLength(2));
      expect(result.popularProducts, hasLength(1));
      expect(result.popularProducts.first.name, isNotEmpty);
      expect(result.meta.hasNext, isTrue);
    });

    test('parses full search payload', () {
      final result = ProductSearchResult.fromEnvelopeData(
        (searchEnvelope(query: 'phone')['data'] as Map<String, dynamic>),
      );

      expect(result.query, 'phone');
      expect(result.products, hasLength(1));
      expect(result.totalResults, greaterThanOrEqualTo(0));
    });
  });
}
