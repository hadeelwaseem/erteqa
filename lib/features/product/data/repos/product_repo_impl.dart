import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:sooq_merchant/core/errors/failures.dart';
import 'package:sooq_merchant/core/utils/app_logger.dart';
import 'package:sooq_merchant/features/product/data/models/category.dart';
import 'package:sooq_merchant/features/product/data/models/product_autocomplete_result.dart';
import 'package:sooq_merchant/features/product/data/models/product_detail.dart';
import 'package:sooq_merchant/features/product/data/models/product_list_response.dart';
import 'package:sooq_merchant/features/product/data/models/product_search_result.dart';
import 'package:sooq_merchant/features/product/data/repos/product_repo.dart';

class ProductRepoImpl implements ProductRepo {
  ProductRepoImpl(
    this._dio, {
    Future<void> Function(Duration) sleep = _defaultSleep,
  }) : _sleep = sleep;

  static const String _productsPath = '/api/v1/public/products';
  static const String _searchPath = '/api/v1/public/products/search';
  static const String _autocompletePath = '/api/v1/public/products/autocomplete';
  static const String _categoriesPath = '/api/v1/public/categories';
  static const Duration _categoriesCacheTtl = Duration(days: 1);
  static const List<Duration> _retryDelays = [
    Duration(milliseconds: 500),
    Duration(seconds: 1),
    Duration(seconds: 2),
  ];
  static const int _maxAttempts = 3;

  final Dio _dio;
  final Future<void> Function(Duration) _sleep;

  List<Category>? _cachedCategories;
  DateTime? _categoriesCachedAt;

  static String _categoryProductsPath(String slug) =>
      '/api/v1/public/categories/$slug/products';

  static String _productDetailPath(String slug) =>
      '/api/v1/public/products/$slug';

  static String _categoryPath(String slug) => '/api/v1/public/categories/$slug';

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
  }) {
    return _executeWithRetry(
      operation: () => _fetchSearch(
        q: q,
        categoryId: categoryId,
        tagId: tagId,
        minPrice: minPrice,
        maxPrice: maxPrice,
        inStockOnly: inStockOnly,
        page: page,
        size: size,
        sort: sort,
        tenantId: tenantId,
        cancelToken: cancelToken,
      ),
    );
  }

  /// Returns [ProductAutocompleteResult.empty] without HTTP when [q] has fewer
  /// than 3 characters (API minimum).
  @override
  Future<Either<Failure, ProductAutocompleteResult>> autocomplete({
    required String q,
    String? tenantId,
    CancelToken? cancelToken,
  }) async {
    if (q.trim().length < 3) {
      return const Right(ProductAutocompleteResult.empty);
    }

    return _executeOnce(
      operation: () => _fetchAutocomplete(
        q: q.trim(),
        tenantId: tenantId,
        cancelToken: cancelToken,
      ),
    );
  }

  @override
  Future<Either<Failure, ProductDetail>> getProductDetail({
    required String slug,
    String? include,
    String? tenantId,
  }) {
    return _executeWithRetry(
      operation: () => _fetchProductDetail(
        slug: slug,
        include: include,
        tenantId: tenantId,
      ),
    );
  }

  @override
  Future<Either<Failure, List<Category>>> getCategories({
    String? tenantId,
  }) async {
    if (_cachedCategories != null &&
        _categoriesCachedAt != null &&
        DateTime.now().difference(_categoriesCachedAt!) < _categoriesCacheTtl) {
      return Right(List<Category>.from(_cachedCategories!));
    }

    final result = await _executeWithRetry(
      operation: () => _fetchCategories(tenantId: tenantId),
    );

    return result.fold(Left.new, (categories) {
      _cachedCategories = List<Category>.from(categories);
      _categoriesCachedAt = DateTime.now();
      return Right(categories);
    });
  }

  @override
  Future<Either<Failure, Category>> getCategory({
    required String slug,
    String? tenantId,
  }) {
    return _executeWithRetry(
      operation: () => _fetchCategory(slug: slug, tenantId: tenantId),
    );
  }

  Future<Either<Failure, T>> _executeOnce<T>({
    required Future<T> Function() operation,
  }) async {
    try {
      final result = await operation();
      return Right(result);
    } on Failure catch (failure) {
      return Left(failure);
    } on DioException catch (error) {
      return Left(_mapDioException(error));
    } catch (error) {
      return Left(ServerFailure('Unexpected error: $error'));
    }
  }

  Future<Either<Failure, T>> _executeWithRetry<T>({
    required Future<T> Function() operation,
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
        if (failure is RequestCancelledFailure) {
          return Left(failure);
        }
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

  Future<ProductSearchResult> _fetchSearch({
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
    final queryParameters = <String, dynamic>{
      'page': page,
      'size': size,
    };
    if (q != null && q.isNotEmpty) {
      queryParameters['q'] = q;
    }
    if (categoryId != null && categoryId.isNotEmpty) {
      queryParameters['categoryId'] = categoryId;
    }
    if (tagId != null && tagId.isNotEmpty) {
      queryParameters['tagId'] = tagId;
    }
    if (minPrice != null) {
      queryParameters['minPrice'] = minPrice;
    }
    if (maxPrice != null) {
      queryParameters['maxPrice'] = maxPrice;
    }
    if (inStockOnly != null) {
      queryParameters['inStockOnly'] = inStockOnly;
    }
    if (sort != null && sort.isNotEmpty) {
      queryParameters['sort'] = sort;
    }

    AppLogger.debug(
      '[ProductRepo] GET $_searchPath q=${q ?? ''} page=$page size=$size '
      'tenant=${tenantId == null || tenantId.isEmpty ? 'empty' : tenantId}',
    );

    final response = await _dio.get(
      _searchPath,
      queryParameters: queryParameters,
      cancelToken: cancelToken,
      options: Options(headers: _buildHeaders(tenantId)),
    );

    final parsed = _parseSearchResponse(response.data);
    AppLogger.debug(
      '[ProductRepo] search success products=${parsed.products.length} '
      'totalResults=${parsed.totalResults}',
    );
    return parsed;
  }

  Future<ProductAutocompleteResult> _fetchAutocomplete({
    required String q,
    String? tenantId,
    CancelToken? cancelToken,
  }) async {
    AppLogger.debug(
      '[ProductRepo] GET $_autocompletePath q=$q '
      'tenant=${tenantId == null || tenantId.isEmpty ? 'empty' : tenantId}',
    );

    final response = await _dio.get(
      _autocompletePath,
      queryParameters: {'q': q},
      cancelToken: cancelToken,
      options: Options(headers: _buildHeaders(tenantId)),
    );

    final parsed = _parseAutocompleteResponse(response.data);
    AppLogger.debug(
      '[ProductRepo] autocomplete success products=${parsed.products.length}',
    );
    return parsed;
  }

  Future<ProductDetail> _fetchProductDetail({
    required String slug,
    String? include,
    String? tenantId,
  }) async {
    final resolvedInclude =
        (include == null || include.isEmpty)
            ? ProductRepo.defaultProductDetailInclude
            : include;
    final path = _productDetailPath(slug);

    AppLogger.debug(
      '[ProductRepo] GET $path include=$resolvedInclude '
      'tenant=${tenantId == null || tenantId.isEmpty ? 'empty' : tenantId}',
    );

    final response = await _dio.get(
      path,
      queryParameters: {'include': resolvedInclude},
      options: Options(headers: _buildHeaders(tenantId)),
    );

    return _parseProductDetailResponse(response.data);
  }

  Future<List<Category>> _fetchCategories({String? tenantId}) async {
    AppLogger.debug(
      '[ProductRepo] GET $_categoriesPath '
      'tenant=${tenantId == null || tenantId.isEmpty ? 'empty' : tenantId}',
    );

    final response = await _dio.get(
      _categoriesPath,
      options: Options(headers: _buildHeaders(tenantId)),
    );

    return _parseCategoriesListResponse(response.data);
  }

  Future<Category> _fetchCategory({
    required String slug,
    String? tenantId,
  }) async {
    final path = _categoryPath(slug);

    AppLogger.debug(
      '[ProductRepo] GET $path '
      'tenant=${tenantId == null || tenantId.isEmpty ? 'empty' : tenantId}',
    );

    final response = await _dio.get(
      path,
      options: Options(headers: _buildHeaders(tenantId)),
    );

    return _parseCategoryResponse(response.data);
  }

  Map<String, String> _buildHeaders(String? tenantId) {
    final headers = <String, String>{'Accept': 'application/json'};
    if (tenantId != null && tenantId.isNotEmpty) {
      headers['X-Tenant-ID'] = tenantId;
    }
    return headers;
  }

  ProductListResponse _parseListResponse(dynamic responseData) {
    final envelope = _normalizeListEnvelope(_requireEnvelope(responseData));

    final meta = envelope['meta'];
    if (meta != null && meta is! Map<String, dynamic>) {
      throw ServerFailure('Products response meta must be an object');
    }

    return ProductListResponse.fromJson(envelope);
  }

  Map<String, dynamic> _normalizeListEnvelope(Map<String, dynamic> envelope) {
    final data = envelope['data'];
    if (data is List) {
      return envelope;
    }

    if (data is Map<String, dynamic>) {
      final items = data['content'] ?? data['products'] ?? data['items'];
      if (items is List) {
        return {
          ...envelope,
          'data': items,
          if (envelope['meta'] == null && data['meta'] is Map<String, dynamic>)
            'meta': data['meta'],
        };
      }
    }

    throw ServerFailure('Products response data must be a list or paged object');
  }

  ProductSearchResult _parseSearchResponse(dynamic responseData) {
    final envelope = _requireEnvelope(responseData);
    final data = envelope['data'];
    if (data is! Map<String, dynamic>) {
      throw ServerFailure('Search response data must be an object');
    }

    return ProductSearchResult.fromEnvelopeData(data);
  }

  ProductAutocompleteResult _parseAutocompleteResponse(dynamic responseData) {
    final envelope = _requireEnvelope(responseData);
    final data = envelope['data'];
    if (data is! Map<String, dynamic>) {
      throw ServerFailure('Autocomplete response data must be an object');
    }

    return ProductAutocompleteResult.fromEnvelopeData(data);
  }

  ProductDetail _parseProductDetailResponse(dynamic responseData) {
    final envelope = _requireEnvelope(responseData);
    final data = envelope['data'];
    if (data is! Map<String, dynamic>) {
      throw ServerFailure('Product detail response data must be an object');
    }

    return ProductDetail.fromEnvelopeData(data);
  }

  List<Category> _parseCategoriesListResponse(dynamic responseData) {
    final envelope = _requireEnvelope(responseData);
    final data = envelope['data'];
    if (data is! List) {
      throw ServerFailure('Categories response data must be a list');
    }

    return data
        .map((item) => Category.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Category _parseCategoryResponse(dynamic responseData) {
    final envelope = _requireEnvelope(responseData);
    final data = envelope['data'];
    if (data is! Map<String, dynamic>) {
      throw ServerFailure('Category response data must be an object');
    }

    return Category.fromJson(data);
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
    if (error.type == DioExceptionType.cancel) {
      return const RequestCancelledFailure();
    }

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
