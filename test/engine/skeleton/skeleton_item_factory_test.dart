import 'package:flutter_test/flutter_test.dart';
import 'package:sooq_merchant/engine/skeleton/skeleton_item_factory.dart';

void main() {
  group('SkeletonItemFactory.resolveCount', () {
    test('uses props.data.size when set', () {
      expect(
        SkeletonItemFactory.resolveCount(
          props: {
            'data': {'size': 6, 'requestUrl': '/api/v1/public/products?page=0'},
          },
          isGrid: true,
          crossAxisCount: 2,
        ),
        6,
      );
    });

    test('parses size from requestUrl query', () {
      expect(
        SkeletonItemFactory.resolveCount(
          props: {
            'data': {
              'requestUrl': '/api/v1/public/products?page=0&size=8',
            },
          },
          isGrid: true,
          crossAxisCount: 2,
        ),
        8,
      );
    });

    test('grid heuristic uses crossAxisCount * 2 capped at 12', () {
      expect(
        SkeletonItemFactory.resolveCount(
          props: const {},
          isGrid: true,
          crossAxisCount: 2,
        ),
        4,
      );
      expect(
        SkeletonItemFactory.resolveCount(
          props: const {},
          isGrid: true,
          crossAxisCount: 6,
        ),
        12,
      );
    });

    test('horizontal list defaults to 4', () {
      expect(
        SkeletonItemFactory.resolveCount(
          props: const {},
          isHorizontal: true,
        ),
        4,
      );
    });

    test('vertical list defaults to 6', () {
      expect(
        SkeletonItemFactory.resolveCount(props: const {}),
        6,
      );
    });
  });

  group('SkeletonItemFactory.items', () {
    test('provides commerce keys for bindings', () {
      final item = SkeletonItemFactory.itemAt(0);
      expect(item['name'], isNotEmpty);
      expect(item['image'], '');
    });
  });
}
