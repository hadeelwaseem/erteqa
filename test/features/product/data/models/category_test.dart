import 'package:flutter_test/flutter_test.dart';
import 'package:sooq_merchant/features/product/data/models/category.dart';

import '../../support/product_test_utils.dart';

void main() {
  group('Category', () {
    test('fromJson parses nested children', () {
      final category = Category.fromJson(
        sampleCategoryItem(
          children: [sampleCategoryItem(slug: 'phones')],
        ),
      );

      expect(category.slug, 'electronics');
      expect(category.children, hasLength(1));
      expect(category.children.first.slug, 'phones');
    });

    test('name prefers Arabic then English', () {
      final category = Category.fromJson({
        'nameAr': 'إلكترونيات',
        'nameEn': 'Electronics',
      });

      expect(category.name, 'إلكترونيات');

      final englishOnly = Category.fromJson({'nameEn': 'Electronics'});
      expect(englishOnly.name, 'Electronics');
    });
  });
}
