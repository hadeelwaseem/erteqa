import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sooq_merchant/core/errors/failures.dart';
import 'package:sooq_merchant/features/product/data/models/category.dart';
import 'package:sooq_merchant/features/product/data/models/product.dart';
import 'package:sooq_merchant/features/product/data/models/product_autocomplete_result.dart';
import 'package:sooq_merchant/features/product/data/models/product_detail.dart';
import 'package:sooq_merchant/features/product/data/models/product_list_response.dart';
import 'package:sooq_merchant/features/product/data/models/product_meta.dart';
import 'package:sooq_merchant/features/product/data/models/product_search_result.dart';
import 'package:sooq_merchant/features/product/data/repos/product_repo.dart';
import 'package:sooq_merchant/features/product/presentation/manager/product_search_cubit/product_search_cubit.dart';

class _FakeProductRepo implements ProductRepo {
  int searchCalls = 0;
  CancelToken? lastCancelToken;

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
    searchCalls += 1;
    lastCancelToken = cancelToken;
    return Right(
      ProductSearchResult(
        query: q,
        products: [
          Product.fromJson({
            'productId': 'id-$page',
            'titleEn': 'Product $page',
            'titleAr': null,
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
        totalResults: 2,
      ),
    );
  }

  @override
  Future<Either<Failure, ProductListResponse>> getProducts({
    required int page,
    required int size,
    String? sort,
    String? tenantId,
  }) =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, ProductListResponse>> getCategoryProducts({
    required String categorySlug,
    required int page,
    required int size,
    String? sort,
    String? tenantId,
  }) =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, ProductAutocompleteResult>> autocomplete({
    required String q,
    String? tenantId,
    CancelToken? cancelToken,
  }) =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, ProductDetail>> getProductDetail({
    required String slug,
    String? include,
    String? tenantId,
  }) =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, List<Category>>> getCategories({String? tenantId}) =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, Category>> getCategory({
    required String slug,
    String? tenantId,
  }) =>
      throw UnimplementedError();
}

void main() {
  group('ProductSearchCubit', () {
    test('debounce delays repo call', () async {
      final repo = _FakeProductRepo();
      final cubit = ProductSearchCubit(repo);

      cubit.search(q: 'phone');
      expect(repo.searchCalls, 0);

      await Future<void>.delayed(const Duration(milliseconds: 350));
      expect(repo.searchCalls, 1);

      await cubit.close();
    });

    test('cancel does not emit failure', () async {
      final repo = _SlowCancelRepo();
      final cubit = ProductSearchCubit(repo);
      final states = <ProductSearchState>[];
      final sub = cubit.stream.listen(states.add);

      cubit.search(q: 'first');
      await Future<void>.delayed(const Duration(milliseconds: 350));
      cubit.search(q: 'second');
      await Future<void>.delayed(const Duration(milliseconds: 400));

      expect(states.whereType<ProductSearchFailure>(), isEmpty);

      await sub.cancel();
      await cubit.close();
    });

    test('loadNextPage appends products on isLoadMore', () async {
      final repo = _FakeProductRepo();
      final cubit = ProductSearchCubit(repo);
      final states = <ProductSearchState>[];
      final sub = cubit.stream.listen(states.add);

      cubit.search(q: 'phone', requestKey: 'search');
      await Future<void>.delayed(const Duration(milliseconds: 350));
      await Future<void>.delayed(Duration.zero);

      final firstSuccess = states.whereType<ProductSearchSuccess>().last;
      await cubit.loadNextPage(
        firstSuccess.searchResult,
        requestKey: 'search',
        q: 'phone',
      );
      await Future<void>.delayed(const Duration(milliseconds: 350));
      await Future<void>.delayed(Duration.zero);

      final success = states.whereType<ProductSearchSuccess>().last;
      expect(success.searchResult.products, hasLength(2));

      await sub.cancel();
      await cubit.close();
    });
  });
}

class _SlowCancelRepo implements ProductRepo {
  @override
  Future<Either<Failure, ProductDetail>> getProductDetail({
    required String slug,
    String? include,
    String? tenantId,
  }) =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, List<Category>>> getCategories({String? tenantId}) =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, Category>> getCategory({
    required String slug,
    String? tenantId,
  }) =>
      throw UnimplementedError();

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
    final completer = Completer<Either<Failure, ProductSearchResult>>();
    cancelToken?.whenCancel.then((_) {
      if (!completer.isCompleted) {
        completer.complete(const Left(RequestCancelledFailure()));
      }
    });
    return completer.future;
  }

  @override
  Future<Either<Failure, ProductAutocompleteResult>> autocomplete({
    required String q,
    String? tenantId,
    CancelToken? cancelToken,
  }) =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, ProductListResponse>> getCategoryProducts({
    required String categorySlug,
    required int page,
    required int size,
    String? sort,
    String? tenantId,
  }) =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, ProductListResponse>> getProducts({
    required int page,
    required int size,
    String? sort,
    String? tenantId,
  }) =>
      throw UnimplementedError();
}
