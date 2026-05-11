import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:sooq_merchant/core/errors/failures.dart';
import 'package:sooq_merchant/core/utils/app_logger.dart';
import 'package:sooq_merchant/core/utils/constants.dart';
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
      final queryParameters = {
        'page': page,
        'size': size,
      };

      final Map<String, String> headers = {
        'Accept': 'application/json',
        'X-Tenant-ID': tenantId,
      };

      AppLogger.debug(
        '[ProductRepo] GET $kBaseUrl/api/v1/public/products '
        'page=$page size=$size tenant=${tenantId.isEmpty ? 'empty' : tenantId}',
      );

      final response = await _dio.get(
        '$kBaseUrl/api/v1/public/products',
        queryParameters: queryParameters,
        options: Options(headers: headers),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final productListResponse =
            ProductListResponse.fromJson(response.data as Map<String, dynamic>);
        AppLogger.debug(
          '[ProductRepo] success items=${productListResponse.data.length} '
          'page=${productListResponse.meta.page} total=${productListResponse.meta.total}',
        );
        return Right(productListResponse);
      } else {
        return Left(
          ServerFailure(
            'Failed to fetch products: ${response.statusCode}',
          ),
        );
      }
    } on DioException catch (e) {
      return Left(ServerFailure.fromDioException(e));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }
}
