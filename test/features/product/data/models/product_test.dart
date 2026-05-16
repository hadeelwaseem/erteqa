import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:sooq_merchant/core/network/network_config.dart';
import 'package:sooq_merchant/features/product/data/models/product.dart';

import '../../support/product_test_utils.dart';

void main() {
  group('Product', () {
    tearDown(() {
      if (GetIt.I.isRegistered<NetworkConfig>()) {
        GetIt.I.unregister<NetworkConfig>();
      }
    });

    test('fromJson maps productId and titleEn to name', () {
      final product = Product.fromJson({
        ...sampleProductItem(),
        'titleAr': null,
      });

      expect(product.productId, '550e8400-e29b-41d4-a716-446655440000');
      expect(product.name, 'Example Product');
      expect(product.price, '1,500.50 SYP');
      expect(product.currency, 'SYP');
    });

    test('image getter is empty when images missing', () {
      final product = Product.fromJson(sampleProductItem());

      expect(product.image, isEmpty);
    });

    test('relative image path resolves with NetworkConfig asset base', () {
      GetIt.I.registerSingleton<NetworkConfig>(
        const NetworkConfig(baseUrl: 'https://cdn.example.com/api/v1'),
      );

      final product = Product.fromJson({
        ...sampleProductItem(),
        'primaryImageUrl': '/uploads/product.jpg',
      });

      expect(product.image, 'https://cdn.example.com/uploads/product.jpg');
    });
  });
}
