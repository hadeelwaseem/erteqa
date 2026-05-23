import 'package:flutter_test/flutter_test.dart';
import 'package:sooq_merchant/features/product/data/models/product_detail.dart';

import '../../support/product_test_utils.dart';

void main() {
  group('ProductDetail', () {
    test('fromEnvelopeData parses full payload', () {
      final detail = ProductDetail.fromEnvelopeData(
        sampleProductDetailData(),
      );

      expect(detail.slug, 'example-product');
      expect(detail.name, isNotEmpty);
      expect(detail.displayPrice, '1,500.50 SYP');
      expect(detail.pricing, isNotNull);
      expect(detail.images, hasLength(1));
      expect(detail.variants, hasLength(1));
      expect(detail.primaryImage?.isPrimary, isTrue);
    });

    test('fromEnvelopeData leaves missing blocks null or empty', () {
      final detail = ProductDetail.fromEnvelopeData(
        sampleProductDetailData(includeVariants: false),
      );

      expect(detail.pricing, isNotNull);
      expect(detail.variants, isEmpty);
    });

    test('fromEnvelopeData resolves primaryImageUrl from images[].url alias', () {
      final detail = ProductDetail.fromEnvelopeData({
        'productId': 'p-1',
        'titleAr': 'منتج',
        'slug': 'sample',
        'images': [
          {'url': 'https://example.com/photo.jpg', 'isPrimary': true},
        ],
      });

      expect(detail.toJson()['primaryImageUrl'], 'https://example.com/photo.jpg');
    });
  });
}
