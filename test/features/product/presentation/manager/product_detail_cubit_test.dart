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
import 'package:sooq_merchant/features/product/presentation/manager/product_detail_cubit/product_detail_cubit.dart';

import '../../support/product_test_utils.dart';

class _FakeProductRepo implements ProductRepo {
  bool shouldFail = false;

  @override
  Future<Either<Failure, ProductDetail>> getProductDetail({
    required String slug,
    String? include,
    String? tenantId,
  }) async {
    if (shouldFail) {
      return Left(ServerFailure('Not found'));
    }
    return Right(ProductDetail.fromEnvelopeData(sampleProductDetailData(slug: slug)));
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
  group('ProductDetailCubit', () {
    test('loadDetail emits loading then success', () async {
      final repo = _FakeProductRepo();
      final cubit = ProductDetailCubit(repo);
      final states = <ProductDetailState>[];
      final sub = cubit.stream.listen(states.add);

      await cubit.loadDetail('example-product');
      await Future<void>.delayed(Duration.zero);

      expect(states.first, isA<ProductDetailLoading>());
      expect(states.last, isA<ProductDetailSuccess>());
      final success = states.last as ProductDetailSuccess;
      expect(success.detail.slug, 'example-product');

      await sub.cancel();
      await cubit.close();
    });

    test('loadDetail emits failure on repo error', () async {
      final repo = _FakeProductRepo()..shouldFail = true;
      final cubit = ProductDetailCubit(repo);
      final states = <ProductDetailState>[];
      final sub = cubit.stream.listen(states.add);

      await cubit.loadDetail('missing');
      await Future<void>.delayed(Duration.zero);

      expect(states.last, isA<ProductDetailFailure>());

      await sub.cancel();
      await cubit.close();
    });
  });
}
