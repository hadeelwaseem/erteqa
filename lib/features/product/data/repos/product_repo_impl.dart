import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:sooq_merchant/core/errors/failures.dart';
import 'package:sooq_merchant/core/utils/app_logger.dart';
import 'package:sooq_merchant/features/product/data/models/product_list_response.dart';
import 'package:sooq_merchant/features/product/data/repos/product_repo.dart';

class ProductRepoImpl implements ProductRepo {
  final Dio _dio;

  ProductRepoImpl(this._dio);

  @override
  Future<Either<Failure, ProductListResponse>> getProducts({
    required int page,
    required int size,
    required String tenantId,
  }) async {
    try {
      const path = '/api/v1/public/products';

      final Map<String, String> headers = {
        'Accept': 'application/json',
        'X-Tenant-ID': tenantId,
      };

      AppLogger.debug(
        '[ProductRepo] GET $path '
        'page=$page size=$size tenant=${tenantId.isEmpty ? 'empty' : tenantId}',
      );

      final response = await _dio.get(
        path,
        queryParameters: {'page': '$page', 'size': '$size'},
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData is! Map<String, dynamic>) {
          return Left(ServerFailure('Unexpected products response format'));
        }

        final productListResponse = ProductListResponse.fromJson(responseData);
        AppLogger.debug(
          '[ProductRepo] success items=${productListResponse.data.length} '
          'page=${productListResponse.meta.page} '
          'total=${productListResponse.meta.total} '
          'totalPages=${productListResponse.meta.totalPages}',
        );
        return Right(productListResponse);
      } else {
        return Left(
          ServerFailure('Failed to fetch products: ${response.statusCode}'),
        );
      }
    } on DioException catch (e) {
      return Left(ServerFailure.fromDioException(e));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }
}
