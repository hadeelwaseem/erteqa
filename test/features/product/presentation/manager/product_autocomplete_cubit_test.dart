import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sooq_merchant/core/errors/failures.dart';
import 'package:sooq_merchant/features/product/data/models/category.dart';
import 'package:sooq_merchant/features/product/data/models/product_autocomplete_result.dart';
import 'package:sooq_merchant/features/product/data/models/product_detail.dart';
import 'package:sooq_merchant/features/product/data/models/product_list_response.dart';
import 'package:sooq_merchant/features/product/data/models/product_search_result.dart';
import 'package:sooq_merchant/features/product/data/repos/product_repo.dart';
import 'package:sooq_merchant/features/product/presentation/manager/product_autocomplete_cubit/product_autocomplete_cubit.dart';

class _FakeProductRepo implements ProductRepo {
  int autocompleteCalls = 0;

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
  Future<Either<Failure, ProductAutocompleteResult>> autocomplete({
    required String q,
    String? tenantId,
    CancelToken? cancelToken,
  }) async {
    autocompleteCalls += 1;
    return const Right(ProductAutocompleteResult.empty);
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
  }) =>
      throw UnimplementedError();
}

void main() {
  group('ProductAutocompleteCubit', () {
    test('fetchSuggestions skips repo when q shorter than 3', () async {
      final repo = _FakeProductRepo();
      final cubit = ProductAutocompleteCubit(repo);

      cubit.fetchSuggestions('ph');

      expect(repo.autocompleteCalls, 0);
      expect(cubit.state, isA<ProductAutocompleteInitial>());

      await cubit.close();
    });

    test('debounce delays repo call for valid q', () async {
      final repo = _FakeProductRepo();
      final cubit = ProductAutocompleteCubit(repo);

      cubit.fetchSuggestions('phone');
      expect(repo.autocompleteCalls, 0);

      await Future<void>.delayed(const Duration(milliseconds: 350));
      expect(repo.autocompleteCalls, 1);

      await cubit.close();
    });

    test('cancel does not emit failure', () async {
      final repo = _CancelAutocompleteRepo();
      final cubit = ProductAutocompleteCubit(repo);
      final states = <ProductAutocompleteState>[];
      final sub = cubit.stream.listen(states.add);

      cubit.fetchSuggestions('phone');
      await Future<void>.delayed(const Duration(milliseconds: 100));
      cubit.fetchSuggestions('phones');
      await Future<void>.delayed(const Duration(milliseconds: 350));

      expect(states.whereType<ProductAutocompleteFailure>(), isEmpty);

      await sub.cancel();
      await cubit.close();
    });
  });
}

class _CancelAutocompleteRepo implements ProductRepo {
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
  Future<Either<Failure, ProductAutocompleteResult>> autocomplete({
    required String q,
    String? tenantId,
    CancelToken? cancelToken,
  }) async {
    return const Left(RequestCancelledFailure());
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
  }) =>
      throw UnimplementedError();
}
