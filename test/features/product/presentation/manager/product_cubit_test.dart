import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sooq_merchant/core/errors/failures.dart';
import 'package:sooq_merchant/features/product/data/models/product.dart';
import 'package:sooq_merchant/features/product/data/models/product_list_response.dart';
import 'package:sooq_merchant/features/product/data/models/product_meta.dart';
import 'package:sooq_merchant/features/product/data/repos/product_repo.dart';
import 'package:sooq_merchant/features/product/presentation/manager/product_cubit/product_cubit.dart';

class _FakeProductRepo implements ProductRepo {
  int getProductsCalls = 0;
  int getCategoryProductsCalls = 0;

  @override
  Future<Either<Failure, ProductListResponse>> getProducts({
    required int page,
    required int size,
    String? sort,
    String? tenantId,
  }) async {
    getProductsCalls += 1;
    return Right(
      ProductListResponse(
        success: true,
        data: [
          Product.fromJson({
            'productId': 'id-$page',
            'titleEn': 'Product $page',
            'displayPrice': '10 SYP',
            'currencyCode': 'SYP',
          }),
        ],
        meta: ProductMeta(
          page: page,
          size: size,
          total: 2,
          totalPages: 2,
          hasNext: page == 0,
          hasPrev: page > 0,
          last: page > 0,
        ),
        timestamp: 0,
      ),
    );
  }

  @override
  Future<Either<Failure, ProductListResponse>> getCategoryProducts({
    required String categorySlug,
    required int page,
    required int size,
    String? sort,
    String? tenantId,
  }) async {
    getCategoryProductsCalls += 1;
    return getProducts(page: page, size: size, sort: sort, tenantId: tenantId);
  }
}

void main() {
  group('ProductCubit', () {
    test('getProducts emits loading then success', () async {
      final repo = _FakeProductRepo();
      final cubit = ProductCubit(repo);
      final states = <ProductState>[];
      final sub = cubit.stream.listen(states.add);

      await cubit.getProducts(page: 0, size: 20);
      await Future<void>.delayed(Duration.zero);

      expect(states.length, greaterThanOrEqualTo(2));
      expect(states.first, isA<ProductLoading>());
      expect(states.last, isA<ProductSuccess>());
      final success = states.last as ProductSuccess;
      expect(success.productListResponse.data.first.name, 'Product 0');

      await sub.cancel();
      await cubit.close();
    });

    test('loadNextPage skips repo when hasNext is false', () async {
      final repo = _FakeProductRepo();
      final cubit = ProductCubit(repo);

      await cubit.loadNextPage(
        ProductListResponse(
          success: true,
          data: const [],
          meta: const ProductMeta(
            page: 1,
            size: 20,
            total: 20,
            totalPages: 1,
            hasNext: false,
            hasPrev: true,
            last: true,
          ),
          timestamp: 0,
        ),
      );

      expect(repo.getProductsCalls, 0);
      expect(repo.getCategoryProductsCalls, 0);
      await cubit.close();
    });

    test('loadNextPage appends items on isLoadMore', () async {
      final repo = _FakeProductRepo();
      final cubit = ProductCubit(repo);
      final states = <ProductState>[];
      final sub = cubit.stream.listen(states.add);

      await cubit.getProducts(page: 0, size: 20, requestKey: 'list');
      await Future<void>.delayed(Duration.zero);
      final firstSuccess = states.whereType<ProductSuccess>().last;
      await cubit.loadNextPage(
        firstSuccess.productListResponse,
        requestKey: 'list',
      );
      await Future<void>.delayed(Duration.zero);

      final success = states.whereType<ProductSuccess>().last;
      expect(success.productListResponse.data, hasLength(2));
      expect(success.productListResponse.data.map((p) => p.name), [
        'Product 0',
        'Product 1',
      ]);

      await sub.cancel();
      await cubit.close();
    });
  });
}
