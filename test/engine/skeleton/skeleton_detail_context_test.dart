import 'package:flutter_test/flutter_test.dart';
import 'package:sooq_merchant/engine/skeleton/skeleton_item_factory.dart';

void main() {
  group('SkeletonItemFactory.detailRequestContext', () {
    test('sets skeletonMode and fake request entry', () {
      const key = 'product-detail';
      final ctx = SkeletonItemFactory.detailRequestContext(null, key);

      expect(ctx[SkeletonItemFactory.skeletonModeKey], isTrue);
      final requests = ctx['requests'] as Map<String, dynamic>;
      final entry = requests[key] as Map<String, dynamic>;
      expect(entry['success'], isTrue);
      final data = entry['data'] as Map<String, dynamic>;
      expect(data['name'], isNotEmpty);
      expect(data['primaryImageUrl'], '');
      expect((data['images'] as List).length, 4);
    });

    test('preserves other request keys', () {
      final ctx = SkeletonItemFactory.detailRequestContext(
        {
          'requests': {
            'other': {'success': true, 'data': {'id': 'x'}},
          },
        },
        'category-detail',
      );

      final requests = ctx['requests'] as Map<String, dynamic>;
      expect(requests.containsKey('other'), isTrue);
      expect(requests.containsKey('category-detail'), isTrue);
    });
  });
}
