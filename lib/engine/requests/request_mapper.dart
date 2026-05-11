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

  const EngineMappedRequest({
    required this.key,
    required this.requestUrl,
    required this.semanticType,
    required this.page,
    required this.size,
  });
}

class EngineRequestMapper {
  static const String _defaultProductRequestKey = 'product-list';

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

    for (final request in requests) {
      if (_isProductListRequest(request)) {
        AppLogger.debug(
          '[RequestMapper] dispatch product request key=${request.key} '
          'url=${request.requestUrl} page=${request.page} size=${request.size} '
          'tenant=${tenantId ?? "not_set_using_default"}',
        );
        if (tenantId != null && tenantId.isNotEmpty) {
          productCubit.setTenantId(tenantId);
        }
        await productCubit.getProducts(
          page: request.page,
          size: request.size,
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
    final pageSize = _parsePageSize(requestUrl, data);

    return EngineMappedRequest(
      key: key,
      requestUrl: requestUrl,
      semanticType: semanticType,
      page: pageSize.$1,
      size: pageSize.$2,
    );
  }

  static bool _isProductListRequest(EngineMappedRequest request) {
    final semantic = request.semanticType?.toLowerCase() ?? '';
    final url = request.requestUrl?.toLowerCase() ?? '';
    return semantic == 'productlist' || url.contains('/products');
  }

  static (int, int) _parsePageSize(String? requestUrl, Map<String, dynamic> data) {
    int page = (data['page'] as num?)?.toInt() ?? 0;
    int size = (data['size'] as num?)?.toInt() ?? (data['limit'] as num?)?.toInt() ?? 20;

    if (requestUrl == null || requestUrl.isEmpty) {
      return (page, size);
    }

    final uri = Uri.tryParse(requestUrl);
    if (uri == null) {
      return (page, size);
    }

    final pageParam = int.tryParse(uri.queryParameters['page'] ?? '');
    final sizeParam = int.tryParse(uri.queryParameters['size'] ?? '');

    return (pageParam ?? page, sizeParam ?? size);
  }
}