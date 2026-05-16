import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sooq_merchant/core/errors/failures.dart';
import 'package:sooq_merchant/core/network/network_config.dart';
import 'package:sooq_merchant/features/product/data/repos/product_repo_impl.dart';

import '../../support/product_test_utils.dart';

Dio _testDio(FakeHttpClientAdapter adapter) {
  return Dio(BaseOptions(baseUrl: NetworkConfig.defaultBaseUrl))
    ..httpClientAdapter = adapter;
}

void main() {
  group('ProductRepoImpl', () {
    test('getProducts returns parsed list on envelope success', () async {
      final adapter = FakeHttpClientAdapter((options) async {
        expect(options.method, 'GET');
        expect(options.path, '/api/v1/public/products');
        expect(options.queryParameters['page'], 0);
        expect(options.queryParameters['size'], 20);
        return jsonResponse(browseProductsEnvelope());
      });
      final repo = ProductRepoImpl(_testDio(adapter), sleep: (_) async {});

      final result = await repo.getProducts(page: 0, size: 20);

      result.fold(
        (failure) => fail('Expected success, got ${failure.errMessage}'),
        (response) {
          expect(response.success, isTrue);
          expect(response.data, hasLength(1));
          expect(response.data.first.name, isNotEmpty);
          expect(response.data.first.price, '1,500.50 SYP');
          expect(response.meta.hasNext, isTrue);
        },
      );
    });

    test('getProducts maps success false to ServerFailure', () async {
      final adapter = FakeHttpClientAdapter((options) async {
        return jsonResponse({
          'success': false,
          'message': 'Request failed',
          'data': null,
        });
      });
      final repo = ProductRepoImpl(_testDio(adapter), sleep: (_) async {});

      final result = await repo.getProducts(page: 0, size: 20);

      result.fold(
        (failure) {
          expect(failure, isA<ServerFailure>());
          expect(failure.errMessage, 'Request failed');
        },
        (_) => fail('Expected failure'),
      );
    });

    test('getProducts rejects non-list data', () async {
      final adapter = FakeHttpClientAdapter((options) async {
        return jsonResponse({
          'success': true,
          'data': {'items': []},
          'meta': {},
        });
      });
      final repo = ProductRepoImpl(_testDio(adapter), sleep: (_) async {});

      final result = await repo.getProducts(page: 0, size: 20);

      result.fold(
        (failure) {
          expect(failure, isA<ServerFailure>());
          expect(failure.errMessage, contains('list'));
        },
        (_) => fail('Expected failure'),
      );
    });

    test('getProducts retries on 429 and succeeds', () async {
      var callCount = 0;
      final adapter = FakeHttpClientAdapter((options) async {
        callCount += 1;
        if (callCount < 3) {
          return jsonResponse(
            {'success': false, 'message': 'Rate limited'},
            statusCode: 429,
          );
        }
        return jsonResponse(browseProductsEnvelope());
      });
      final repo = ProductRepoImpl(_testDio(adapter), sleep: (_) async {});

      final result = await repo.getProducts(page: 0, size: 20);

      expect(callCount, 3);
      expect(adapter.requests, hasLength(3));
      result.fold(
        (failure) => fail('Expected success, got ${failure.errMessage}'),
        (response) => expect(response.data, hasLength(1)),
      );
    });

    test('getProducts sends tenant header when tenantId provided', () async {
      final adapter = FakeHttpClientAdapter((options) async {
        expect(options.headers['X-Tenant-ID'], 'tenant-abc');
        return jsonResponse(browseProductsEnvelope());
      });
      final repo = ProductRepoImpl(_testDio(adapter), sleep: (_) async {});

      await repo.getProducts(page: 0, size: 20, tenantId: 'tenant-abc');
    });

    test('getProducts omits tenant header when tenantId empty', () async {
      final adapter = FakeHttpClientAdapter((options) async {
        expect(options.headers.containsKey('X-Tenant-ID'), isFalse);
        return jsonResponse(browseProductsEnvelope());
      });
      final repo = ProductRepoImpl(_testDio(adapter), sleep: (_) async {});

      await repo.getProducts(page: 0, size: 20, tenantId: '');
    });

    test('getCategoryProducts uses category path', () async {
      final adapter = FakeHttpClientAdapter((options) async {
        expect(options.path, '/api/v1/public/categories/electronics/products');
        return jsonResponse(categoryProductsEnvelope());
      });
      final repo = ProductRepoImpl(_testDio(adapter), sleep: (_) async {});

      final result = await repo.getCategoryProducts(
        categorySlug: 'electronics',
        page: 0,
        size: 20,
        sort: 'basePrice,asc',
      );

      result.fold(
        (failure) => fail('Expected success, got ${failure.errMessage}'),
        (response) => expect(response.data, hasLength(1)),
      );
      expect(adapter.requests.first.queryParameters['sort'], 'basePrice,asc');
    });
  });
}
