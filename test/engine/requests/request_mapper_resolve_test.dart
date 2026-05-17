import 'package:flutter_test/flutter_test.dart';
import 'package:sooq_merchant/engine/requests/request_mapper.dart';

void main() {
  group('EngineRequestMapper.resolveRequestUrl', () {
    test('replaces route param placeholders', () {
      final resolved = EngineRequestMapper.resolveRequestUrl(
        '/api/v1/public/products/:productId',
        routeParams: {'productId': 'example-product'},
      );

      expect(resolved, '/api/v1/public/products/example-product');
    });

    test('replaces category slug in category products path', () {
      final resolved = EngineRequestMapper.resolveRequestUrl(
        '/api/v1/public/categories/:categorySlug/products?page=0&size=20',
        routeParams: {'categorySlug': 'electronics'},
      );

      expect(
        resolved,
        '/api/v1/public/categories/electronics/products?page=0&size=20',
      );
    });

    test('returns null when placeholders remain unresolved', () {
      final resolved = EngineRequestMapper.resolveRequestUrl(
        '/api/v1/public/products/:productId',
      );

      expect(resolved, isNull);
    });
  });
}
