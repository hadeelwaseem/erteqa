import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sooq_merchant/core/errors/failures.dart';
import 'package:sooq_merchant/core/network/network_config.dart';
import 'package:sooq_merchant/features/product/data/repos/product_repo.dart';
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

    test('getProducts accepts paged object with items array', () async {
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
        (_) => fail('Expected success'),
        (response) => expect(response.data, isEmpty),
      );
    });

    test('getProducts rejects unrecognized data shape', () async {
      final adapter = FakeHttpClientAdapter((options) async {
        return jsonResponse({
          'success': true,
          'data': {'unexpected': true},
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

    test('searchProducts parses nested data object', () async {
      final adapter = FakeHttpClientAdapter((options) async {
        expect(options.path, '/api/v1/public/products/search');
        expect(options.queryParameters['q'], 'phone');
        return jsonResponse(searchEnvelope());
      });
      final repo = ProductRepoImpl(_testDio(adapter), sleep: (_) async {});

      final result = await repo.searchProducts(q: 'phone', page: 0, size: 20);

      result.fold(
        (failure) => fail('Expected success, got ${failure.errMessage}'),
        (searchResult) {
          expect(searchResult.products, hasLength(1));
          expect(searchResult.query, 'phone');
          expect(searchResult.meta.hasNext, isTrue);
        },
      );
    });

    test('searchProducts maps success false to ServerFailure', () async {
      final adapter = FakeHttpClientAdapter((options) async {
        return jsonResponse({
          'success': false,
          'message': 'Search failed',
          'data': null,
        });
      });
      final repo = ProductRepoImpl(_testDio(adapter), sleep: (_) async {});

      final result = await repo.searchProducts(q: 'phone', page: 0, size: 20);

      result.fold(
        (failure) {
          expect(failure, isA<ServerFailure>());
          expect(failure.errMessage, 'Search failed');
        },
        (_) => fail('Expected failure'),
      );
    });

    test('searchProducts maps cancel to RequestCancelledFailure', () async {
      final adapter = FakeHttpClientAdapter((options) async {
        throw DioException(
          requestOptions: options,
          type: DioExceptionType.cancel,
        );
      });
      final repo = ProductRepoImpl(_testDio(adapter), sleep: (_) async {});

      final result = await repo.searchProducts(
        q: 'phone',
        page: 0,
        size: 20,
        cancelToken: CancelToken(),
      );

      result.fold(
        (failure) => expect(failure, isA<RequestCancelledFailure>()),
        (_) => fail('Expected cancel failure'),
      );
    });

    test('autocomplete uses autocomplete path', () async {
      final adapter = FakeHttpClientAdapter((options) async {
        expect(options.path, '/api/v1/public/products/autocomplete');
        expect(options.queryParameters['q'], 'phone');
        return jsonResponse(autocompleteEnvelope());
      });
      final repo = ProductRepoImpl(_testDio(adapter), sleep: (_) async {});

      final result = await repo.autocomplete(q: 'phone');

      result.fold(
        (failure) => fail('Expected success, got ${failure.errMessage}'),
        (autocompleteResult) {
          expect(autocompleteResult.products, hasLength(1));
          expect(autocompleteResult.suggestions, isNotEmpty);
        },
      );
    });

    test('getProductDetail uses product path and default include', () async {
      final adapter = FakeHttpClientAdapter((options) async {
        expect(options.path, '/api/v1/public/products/example-product');
        expect(
          options.queryParameters['include'],
          ProductRepo.defaultProductDetailInclude,
        );
        return jsonResponse(productDetailEnvelope());
      });
      final repo = ProductRepoImpl(_testDio(adapter), sleep: (_) async {});

      final result = await repo.getProductDetail(slug: 'example-product');

      result.fold(
        (failure) => fail('Expected success, got ${failure.errMessage}'),
        (detail) {
          expect(detail.slug, 'example-product');
          expect(detail.displayPrice, isNotEmpty);
          expect(detail.variants, hasLength(1));
        },
      );
    });

    test('getProductDetail maps 404 to ServerFailure', () async {
      final adapter = FakeHttpClientAdapter((options) async {
        return jsonResponse(
          {'success': false, 'message': 'Product not found'},
          statusCode: 404,
        );
      });
      final repo = ProductRepoImpl(_testDio(adapter), sleep: (_) async {});

      final result = await repo.getProductDetail(slug: 'missing');

      result.fold(
        (failure) {
          expect(failure, isA<ServerFailure>());
          expect(failure.errMessage, isNotEmpty);
        },
        (_) => fail('Expected failure'),
      );
    });

    test('getProductDetail rejects non-object data', () async {
      final adapter = FakeHttpClientAdapter((options) async {
        return jsonResponse({
          'success': true,
          'data': [],
        });
      });
      final repo = ProductRepoImpl(_testDio(adapter), sleep: (_) async {});

      final result = await repo.getProductDetail(slug: 'example-product');

      result.fold(
        (failure) {
          expect(failure, isA<ServerFailure>());
          expect(failure.errMessage, contains('object'));
        },
        (_) => fail('Expected failure'),
      );
    });

    test('getCategories returns parsed tree', () async {
      final adapter = FakeHttpClientAdapter((options) async {
        expect(options.path, '/api/v1/public/categories');
        return jsonResponse(categoryTreeEnvelope());
      });
      final repo = ProductRepoImpl(_testDio(adapter), sleep: (_) async {});

      final result = await repo.getCategories();

      result.fold(
        (failure) => fail('Expected success, got ${failure.errMessage}'),
        (categories) {
          expect(categories, hasLength(1));
          expect(categories.first.children, hasLength(1));
        },
      );
    });

    test('getCategories uses in-memory cache on second call', () async {
      var callCount = 0;
      final adapter = FakeHttpClientAdapter((options) async {
        callCount += 1;
        return jsonResponse(categoryTreeEnvelope());
      });
      final repo = ProductRepoImpl(_testDio(adapter), sleep: (_) async {});

      await repo.getCategories();
      await repo.getCategories();

      expect(callCount, 1);
    });

    test('getCategory uses category path', () async {
      final adapter = FakeHttpClientAdapter((options) async {
        expect(options.path, '/api/v1/public/categories/electronics');
        return jsonResponse(singleCategoryEnvelope(slug: 'electronics'));
      });
      final repo = ProductRepoImpl(_testDio(adapter), sleep: (_) async {});

      final result = await repo.getCategory(slug: 'electronics');

      result.fold(
        (failure) => fail('Expected success, got ${failure.errMessage}'),
        (category) {
          expect(category.slug, 'electronics');
          expect(category.children, hasLength(1));
        },
      );
    });

    test('autocomplete skips HTTP when q shorter than 3 characters', () async {
      final adapter = FakeHttpClientAdapter((options) async {
        return jsonResponse(autocompleteEnvelope());
      });
      final repo = ProductRepoImpl(_testDio(adapter), sleep: (_) async {});

      final result = await repo.autocomplete(q: 'ph');

      expect(adapter.requests, isEmpty);
      result.fold(
        (failure) => fail('Expected success, got ${failure.errMessage}'),
        (autocompleteResult) {
          expect(autocompleteResult.products, isEmpty);
          expect(autocompleteResult.suggestions, isEmpty);
        },
      );
    });
  });
}

