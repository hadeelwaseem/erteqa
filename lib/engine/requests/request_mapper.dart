import 'package:sooq_merchant/config/component_config.dart';
import 'package:sooq_merchant/config/screen_config.dart';
import 'package:sooq_merchant/core/utils/app_logger.dart';
import 'package:sooq_merchant/features/product/presentation/manager/product_cubit/product_cubit.dart';

class EngineMappedRequest {
  final String key;
  final String? requestUrl;
  final String? semanticType;
  final int page;
  final int size;
  final String? sort;

  const EngineMappedRequest({
    required this.key,
    required this.requestUrl,
    required this.semanticType,
    required this.page,
    required this.size,
    this.sort,
  });
}

class EngineRequestMapper {
  static const String _defaultProductRequestKey = 'product-list';
  static final RegExp _categoryProductsPattern = RegExp(
    r'/categories/([^/]+)/products',
    caseSensitive: false,
  );

  static List<EngineMappedRequest> collectRequests(ScreenConfig config) {
    final mapped = <EngineMappedRequest>[];
    _collectFromNode(config.root, mapped);
    AppLogger.debug('[RequestMapper] collected requests: ${mapped.length}');
    return mapped;
  }

  static Future<void> dispatchRequests({
    required ProductCubit productCubit,
    required String? tenantId,
    required List<EngineMappedRequest> requests,
  }) async {
    if (requests.isEmpty) return;

    if (tenantId != null && tenantId.isNotEmpty) {
      productCubit.setTenantId(tenantId);
    }

    for (final request in requests) {
      final page = request.page;
      final size = request.size;
      final sort = request.sort;

      if (_isCategoryProductsRequest(request)) {
        final slug = _parseCategorySlug(request.requestUrl);
        if (slug == null || slug.isEmpty) {
          continue;
        }

        AppLogger.debug(
          '[RequestMapper] dispatch category products key=${request.key} '
          'slug=$slug url=${request.requestUrl} page=$page size=$size '
          'tenant=${tenantId ?? "not_set"}',
        );
        await productCubit.getCategoryProducts(
          categorySlug: slug,
          page: page,
          size: size,
          sort: sort,
          requestKey: request.key,
        );
        continue;
      }

      if (_isBrowseProductsRequest(request)) {
        AppLogger.debug(
          '[RequestMapper] dispatch browse products key=${request.key} '
          'url=${request.requestUrl} page=$page size=$size '
          'tenant=${tenantId ?? "not_set"}',
        );
        await productCubit.getProducts(
          page: page,
          size: size,
          sort: sort,
          requestKey: request.key,
        );
      }
    }
  }

  static void _collectFromNode(
    ComponentConfig node,
    List<EngineMappedRequest> collector,
  ) {
    final mapped = _buildMappedRequest(node);
    if (mapped != null) {
      collector.add(mapped);
    }

    final child = node.child;
    if (child != null) {
      _collectFromNode(child, collector);
    }

    final children = node.children;
    if (children != null) {
      for (final entry in children) {
        _collectFromNode(entry, collector);
      }
    }
  }

  static EngineMappedRequest? _buildMappedRequest(ComponentConfig node) {
    final semanticType = node.properties['semanticType'] as String?;
    final data = node.properties['data'];
    if (data is! Map<String, dynamic>) {
      return null;
    }

    final requestUrl = data['requestUrl'] as String?;
    final explicitKey =
        data['requestKey'] as String? ?? data['requestId'] as String?;
    final nodeId = node.properties['id'] as String?;

    if (requestUrl == null && explicitKey == null) {
      return null;
    }

    final key = explicitKey ?? requestUrl ?? semanticType ?? nodeId ??
        _defaultProductRequestKey;
    final pageSize = _parseListQuery(requestUrl, data);

    return EngineMappedRequest(
      key: key,
      requestUrl: requestUrl,
      semanticType: semanticType,
      page: pageSize.$1,
      size: pageSize.$2,
      sort: pageSize.$3,
    );
  }

  static bool _isBrowseProductsRequest(EngineMappedRequest request) {
    final semantic = request.semanticType?.toLowerCase() ?? '';
    if (semantic == 'productlist' &&
        (request.requestUrl == null || request.requestUrl!.isEmpty)) {
      return true;
    }

    final url = request.requestUrl?.toLowerCase() ?? '';
    if (url.isEmpty) {
      return semantic == 'productlist';
    }

    if (!url.contains('/public/products')) {
      return false;
    }
    if (url.contains('/search') || url.contains('/autocomplete')) {
      return false;
    }

    final uri = Uri.tryParse(url);
    if (uri == null) {
      return url.endsWith('/products') || url.contains('/products?');
    }

    return uri.path.endsWith('/products');
  }

  static bool _isCategoryProductsRequest(EngineMappedRequest request) {
    final url = request.requestUrl?.toLowerCase() ?? '';
    if (url.isEmpty) {
      return false;
    }
    return _categoryProductsPattern.hasMatch(url);
  }

  static String? _parseCategorySlug(String? requestUrl) {
    if (requestUrl == null || requestUrl.isEmpty) {
      return null;
    }
    return _categoryProductsPattern.firstMatch(requestUrl)?.group(1);
  }

  static (int, int, String?) _parseListQuery(
    String? requestUrl,
    Map<String, dynamic> data,
  ) {
    int page = (data['page'] as num?)?.toInt() ?? 0;
    int size =
        (data['size'] as num?)?.toInt() ??
        (data['limit'] as num?)?.toInt() ??
        20;
    String? sort = data['sort'] as String?;

    if (requestUrl == null || requestUrl.isEmpty) {
      return (page, size, sort);
    }

    final uri = Uri.tryParse(requestUrl);
    if (uri == null) {
      return (page, size, sort);
    }

    final pageParam = int.tryParse(uri.queryParameters['page'] ?? '');
    final sizeParam = int.tryParse(uri.queryParameters['size'] ?? '');
    final sortParam = uri.queryParameters['sort'];

    return (
      pageParam ?? page,
      sizeParam ?? size,
      sortParam?.isNotEmpty == true ? sortParam : sort,
    );
  }
}
