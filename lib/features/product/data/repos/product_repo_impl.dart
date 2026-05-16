import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:sooq_merchant/core/errors/failures.dart';
import 'package:sooq_merchant/core/utils/app_logger.dart';
import 'package:sooq_merchant/features/product/data/models/product_list_response.dart';
import 'package:sooq_merchant/features/product/data/repos/product_repo.dart';

class ProductRepoImpl implements ProductRepo {
  ProductRepoImpl(
    this._dio, {
    Future<void> Function(Duration) sleep = _defaultSleep,
  }) : _sleep = sleep;

  static const String _productsPath = '/api/v1/public/products';
  static const List<Duration> _retryDelays = [
    Duration(milliseconds: 500),
    Duration(seconds: 1),
    Duration(seconds: 2),
  ];
  static const int _maxAttempts = 3;

  final Dio _dio;
  final Future<void> Function(Duration) _sleep;

  static String _categoryProductsPath(String slug) =>
      '/api/v1/public/categories/$slug/products';

  @override
  Future<Either<Failure, ProductListResponse>> getProducts({
    required int page,
    required int size,
    String? sort,
    String? tenantId,
  }) {
    return _executeWithRetry(
      operation: () => _fetchList(
        path: _productsPath,
        page: page,
        size: size,
        sort: sort,
        tenantId: tenantId,
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
  }) {
    return _executeWithRetry(
      operation: () => _fetchList(
        path: _categoryProductsPath(categorySlug),
        page: page,
        size: size,
        sort: sort,
        tenantId: tenantId,
      ),
    );
  }

  Future<Either<Failure, ProductListResponse>> _executeWithRetry({
    required Future<ProductListResponse> Function() operation,
  }) async {
    var attempt = 0;
    while (true) {
      attempt += 1;
      try {
        final result = await operation();
        return Right(result);
      } on Failure catch (failure) {
        return Left(failure);
      } on DioException catch (error) {
        final failure = _mapDioException(error);
        final shouldRetry = _shouldRetry(error, attempt);
        if (!shouldRetry) {
          return Left(failure);
        }

        final delayIndex = (attempt - 1).clamp(0, _retryDelays.length - 1);
        await _sleep(_retryDelays[delayIndex]);
      } catch (error) {
        return Left(ServerFailure('Unexpected error: $error'));
      }
    }
  }

  Future<ProductListResponse> _fetchList({
    required String path,
    required int page,
    required int size,
    String? sort,
    String? tenantId,
  }) async {
    final queryParameters = <String, dynamic>{
      'page': page,
      'size': size,
    };
    if (sort != null && sort.isNotEmpty) {
      queryParameters['sort'] = sort;
    }

    AppLogger.debug(
      '[ProductRepo] GET $path '
      'page=$page size=$size sort=${sort ?? 'default'} '
      'tenant=${tenantId == null || tenantId.isEmpty ? 'empty' : tenantId}',
    );

    final response = await _dio.get(
      path,
      queryParameters: queryParameters,
      options: Options(headers: _buildHeaders(tenantId)),
    );

    final parsed = _parseListResponse(response.data);
    AppLogger.debug(
      '[ProductRepo] success items=${parsed.data.length} '
      'page=${parsed.meta.page} total=${parsed.meta.total} '
      'totalPages=${parsed.meta.totalPages}',
    );
    return parsed;
  }

  Map<String, String> _buildHeaders(String? tenantId) {
    final headers = <String, String>{'Accept': 'application/json'};
    if (tenantId != null && tenantId.isNotEmpty) {
      headers['X-Tenant-ID'] = tenantId;
    }
    return headers;
  }

  ProductListResponse _parseListResponse(dynamic responseData) {
    final envelope = _requireEnvelope(responseData);
    final data = envelope['data'];
    if (data is! List) {
      throw ServerFailure('Products response data must be a list');
    }

    final meta = envelope['meta'];
    if (meta != null && meta is! Map<String, dynamic>) {
      throw ServerFailure('Products response meta must be an object');
    }

    return ProductListResponse.fromJson(envelope);
  }

  Map<String, dynamic> _requireEnvelope(dynamic responseData) {
    if (responseData is! Map<String, dynamic>) {
      throw ServerFailure('API response is not a JSON object');
    }

    final success = responseData['success'];
    if (success is bool && !success) {
      throw ServerFailure(
        _readString(responseData, const ['message', 'detail']) ??
            'Request failed',
      );
    }

    return responseData;
  }

  bool _shouldRetry(DioException error, int attempt) {
    if (attempt >= _maxAttempts) {
      return false;
    }

    final statusCode = error.response?.statusCode;
    if (statusCode == 429) {
      return true;
    }
    if (statusCode != null && statusCode >= 500) {
      return true;
    }

    return _isNetworkIssue(error);
  }

  bool _isNetworkIssue(DioException error) {
    return switch (error.type) {
      DioExceptionType.connectionError ||
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.unknown => true,
      _ => false,
    };
  }

  Failure _mapDioException(DioException error) {
    final response = error.response;
    if (response == null) {
      AppLogger.debug(
        '[ProductRepo] HTTP error (no response): ${error.message} '
        'type=${error.type}',
      );
      return ServerFailure.fromDioException(error);
    }

    final statusCode = response.statusCode;
    final payload = response.data;
    AppLogger.debug(
      '[ProductRepo] HTTP $statusCode ${error.requestOptions.path} '
      'response=$payload',
    );

    return ServerFailure.fromResponse(statusCode, payload);
  }

  String? _readString(Map<String, dynamic> payload, List<String> keys) {
    for (final key in keys) {
      final value = payload[key];
      if (value is String && value.isNotEmpty) {
        return value;
      }
    }
    return null;
  }

  static Future<void> _defaultSleep(Duration duration) => Future.delayed(duration);
}
