import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:sooq_merchant/core/errors/failures.dart';
import 'package:sooq_merchant/core/utils/app_logger.dart';
import 'package:sooq_merchant/dev/product_mock/product_mock_config.dart';
import 'package:sooq_merchant/dev/product_mock/mock_product_data.dart';
import 'package:sooq_merchant/features/product/data/models/product_list_response.dart';
import 'package:sooq_merchant/features/product/data/models/product_search_result.dart';
import 'package:sooq_merchant/features/product/data/models/product_autocomplete_result.dart';
import 'package:sooq_merchant/features/product/data/models/product_detail.dart';
import 'package:sooq_merchant/features/product/data/models/category.dart';
import 'package:sooq_merchant/features/product/data/repos/product_repo.dart';

class MockProductRepo implements ProductRepo {
  MockProductRepo();

  Future<void> _delay() => Future<void>.delayed(ProductMockConfig.requestDelay);

  @override
  Future<Either<Failure, ProductListResponse>> getProducts({
    required int page,
    required int size,
    String? sort,
    String? tenantId,
  }) async {
    AppLogger.network(
      '[MOCK] getProducts page=$page size=$size sort=$sort tenant=$tenantId',
    );
    await _delay();
    try {
      final resp = MockProductData.productList(
        page: page,
        size: size,
        sort: sort,
      );
      return Right(resp);
    } catch (e) {
      return Left(ServerFailure('Mock getProducts failed'));
    }
  }

  @override
  Future<Either<Failure, ProductListResponse>> getCategoryProducts({
    required String categorySlug,
    required int page,
    required int size,
    String? sort,
    String? tenantId,
  }) async {
    AppLogger.network(
      '[MOCK] getCategoryProducts category=$categorySlug page=$page size=$size',
    );
    await _delay();
    try {
      final all = MockProductData.productList(
        page: 0,
        size: ProductMockConfig.sampleProductCount,
      );
      final filtered = all.data
          .where(
            (p) => (p.slug ?? '').contains(
              categorySlug.replaceAll('category-', 'product-'),
            ),
          )
          .toList();
      final total = filtered.length;
      final totalPages = (total / size).ceil();
      final start = page * size;
      final end = start + size;
      final slice = start >= total
          ? <dynamic>[]
          : filtered.sublist(start, end > total ? total : end);

      final meta = ProductListResponse(
        success: true,
        message: null,
        data: slice.cast(),
        meta: all.meta.copyWith(
          page: page,
          size: size,
          total: total,
          totalPages: totalPages,
        ),
        timestamp: DateTime.now().toUtc().millisecondsSinceEpoch,
      );

      return Right(meta);
    } catch (e) {
      return Left(ServerFailure('Mock getCategoryProducts failed'));
    }
  }

  @override
  Future<Either<Failure, ProductSearchResult>> searchProducts({
    String? q,
    String? categoryId,
    String? tagId,
    double? minPrice,
    double? maxPrice,
    bool? inStockOnly,
    required int page,
    required int size,
    String? sort,
    String? tenantId,
    CancelToken? cancelToken,
  }) async {
    AppLogger.network('[MOCK] searchProducts q=$q page=$page size=$size');
    await _delay();
    try {
      final resp = MockProductData.search(
        q: q,
        categoryId: categoryId,
        tagId: tagId,
        minPrice: minPrice,
        maxPrice: maxPrice,
        inStockOnly: inStockOnly,
        page: page,
        size: size,
        sort: sort,
      );
      return Right(resp);
    } catch (e) {
      return Left(ServerFailure('Mock searchProducts failed'));
    }
  }

  @override
  Future<Either<Failure, ProductAutocompleteResult>> autocomplete({
    required String q,
    String? tenantId,
    CancelToken? cancelToken,
  }) async {
    AppLogger.network('[MOCK] autocomplete q=$q');
    await _delay();
    try {
      final resp = MockProductData.autocomplete(q: q);
      return Right(resp);
    } catch (e) {
      return Left(ServerFailure('Mock autocomplete failed'));
    }
  }

  @override
  Future<Either<Failure, ProductDetail>> getProductDetail({
    required String slug,
    String? include,
    String? tenantId,
  }) async {
    AppLogger.network('[MOCK] getProductDetail slug=$slug');
    await _delay();
    try {
      final resp = MockProductData.productDetail(slug);
      return Right(resp);
    } catch (e) {
      return Left(ServerFailure('Mock getProductDetail failed'));
    }
  }

  @override
  Future<Either<Failure, List<Category>>> getCategories({
    String? tenantId,
  }) async {
    AppLogger.network('[MOCK] getCategories');
    await _delay();
    try {
      final resp = MockProductData.categories();
      return Right(resp);
    } catch (e) {
      return Left(ServerFailure('Mock getCategories failed'));
    }
  }

  @override
  Future<Either<Failure, Category>> getCategory({
    required String slug,
    String? tenantId,
  }) async {
    AppLogger.network('[MOCK] getCategory slug=$slug');
    await _delay();
    try {
      final resp = MockProductData.categoryBySlug(slug);
      return Right(resp);
    } catch (e) {
      return Left(ServerFailure('Mock getCategory failed'));
    }
  }
}
