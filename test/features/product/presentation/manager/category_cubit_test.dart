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
import 'package:sooq_merchant/features/product/presentation/manager/category_cubit/category_cubit.dart';

class _FakeProductRepo implements ProductRepo {
  bool shouldFail = false;

  @override
  Future<Either<Failure, List<Category>>> getCategories({String? tenantId}) async {
    if (shouldFail) {
      return Left(ServerFailure('Failed'));
    }
    return Right([
      const Category(slug: 'electronics', nameEn: 'Electronics'),
    ]);
  }

  @override
  Future<Either<Failure, Category>> getCategory({
    required String slug,
    String? tenantId,
  }) async {
    if (shouldFail) {
      return Left(ServerFailure('Failed'));
    }
    return Right(Category(slug: slug, nameEn: slug));
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
}

void main() {
  group('CategoryCubit', () {
    test('loadTree emits loading then tree success', () async {
      final repo = _FakeProductRepo();
      final cubit = CategoryCubit(repo);
      final states = <CategoryState>[];
      final sub = cubit.stream.listen(states.add);

      await cubit.loadTree();
      await Future<void>.delayed(Duration.zero);

      expect(states.first, isA<CategoryLoading>());
      expect(states.last, isA<CategoryTreeSuccess>());
      final success = states.last as CategoryTreeSuccess;
      expect(success.categories, hasLength(1));

      await sub.cancel();
      await cubit.close();
    });

    test('loadCategory emits loading then category success', () async {
      final repo = _FakeProductRepo();
      final cubit = CategoryCubit(repo);
      final states = <CategoryState>[];
      final sub = cubit.stream.listen(states.add);

      await cubit.loadCategory('electronics');
      await Future<void>.delayed(Duration.zero);

      expect(states.first, isA<CategoryLoading>());
      expect(states.last, isA<CategorySuccess>());
      final success = states.last as CategorySuccess;
      expect(success.category.slug, 'electronics');

      await sub.cancel();
      await cubit.close();
    });

    test('loadTree emits failure on repo error', () async {
      final repo = _FakeProductRepo()..shouldFail = true;
      final cubit = CategoryCubit(repo);
      final states = <CategoryState>[];
      final sub = cubit.stream.listen(states.add);

      await cubit.loadTree();
      await Future<void>.delayed(Duration.zero);

      expect(states.last, isA<CategoryFailure>());

      await sub.cancel();
      await cubit.close();
    });
  });
}
