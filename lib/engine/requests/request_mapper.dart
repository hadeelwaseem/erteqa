import 'package:sooq_merchant/config/component_config.dart';
import 'package:sooq_merchant/config/screen_config.dart';
import 'package:sooq_merchant/core/utils/app_logger.dart';
import 'package:sooq_merchant/features/commerce/checkout/presentation/manager/checkout_cubit/checkout_cubit.dart';
import 'package:sooq_merchant/features/commerce/order/presentation/manager/order_cubit/order_cubit.dart';
import 'package:sooq_merchant/features/product/presentation/manager/category_cubit/category_cubit.dart';
import 'package:sooq_merchant/features/product/presentation/manager/product_autocomplete_cubit/product_autocomplete_cubit.dart';
import 'package:sooq_merchant/features/product/presentation/manager/product_cubit/product_cubit.dart';
import 'package:sooq_merchant/features/product/presentation/manager/product_detail_cubit/product_detail_cubit.dart';
import 'package:sooq_merchant/features/product/presentation/manager/product_search_cubit/product_search_cubit.dart';

class EnginePrimeFromRequest {
  const EnginePrimeFromRequest({
    required this.sourceRequestKey,
    required this.itemField,
    required this.pageStateKey,
  });

  final String sourceRequestKey;
  final String itemField;
  final String pageStateKey;

  static EnginePrimeFromRequest? fromData(Map<String, dynamic>? data) {
    if (data == null) {
      return null;
    }
    final sourceRequestKey = data['sourceRequestKey'] as String?;
    final itemField = data['itemField'] as String?;
    final pageStateKey = data['pageStateKey'] as String?;
    if (sourceRequestKey == null ||
        sourceRequestKey.isEmpty ||
        itemField == null ||
        itemField.isEmpty ||
        pageStateKey == null ||
        pageStateKey.isEmpty) {
      return null;
    }
    return EnginePrimeFromRequest(
      sourceRequestKey: sourceRequestKey,
      itemField: itemField,
      pageStateKey: pageStateKey,
    );
  }
}

class EngineMappedRequest {
  final String key;
  final String? requestUrl;
  final String? rawRequestUrl;
  final String? semanticType;
  final int page;
  final int size;
  final String? sort;
  final String? q;
  final String? categoryId;
  final String? tagId;
  final double? minPrice;
  final double? maxPrice;
  final bool? inStockOnly;
  final String? include;
  final String? qField;
  final Map<String, dynamic>? queryBindings;
  final Map<String, dynamic>? pathBindings;
  final bool deferInitialDispatch;
  final EnginePrimeFromRequest? primeFromRequest;
  final String? fallbackRequestUrl;
  final Map<String, dynamic> sourceData;

  const EngineMappedRequest({
    required this.key,
    required this.requestUrl,
    this.rawRequestUrl,
    required this.semanticType,
    required this.page,
    required this.size,
    this.sort,
    this.q,
    this.categoryId,
    this.tagId,
    this.minPrice,
    this.maxPrice,
    this.inStockOnly,
    this.include,
    this.qField,
    this.queryBindings,
    this.pathBindings,
    this.deferInitialDispatch = false,
    this.primeFromRequest,
    this.fallbackRequestUrl,
    this.sourceData = const {},
  });
}

class EngineRequestMapper {
  static const String _defaultProductRequestKey = 'product-list';
  static final RegExp _categoryProductsPattern = RegExp(
    r'/categories/([^/]+)/products',
    caseSensitive: false,
  );

  static bool needsProductCubit(List<EngineMappedRequest> requests) =>
      requests.any(supportsProductListLoadMore);

  /// Browse and category product lists use [ProductListResponse] pagination.
  static bool supportsProductListLoadMore(EngineMappedRequest request) =>
      _isBrowseProductsRequest(request) ||
      _isCategoryProductsRequest(request);

  static bool needsSearchCubit(List<EngineMappedRequest> requests) =>
      requests.any(_isSearchRequest);

  static bool needsAutocompleteCubit(List<EngineMappedRequest> requests) =>
      requests.any(_isAutocompleteRequest);

  static bool needsProductDetailCubit(List<EngineMappedRequest> requests) =>
      requests.any(_isProductDetailRequest);

  static bool needsCategoryCubit(List<EngineMappedRequest> requests) =>
      requests.any(
        (request) =>
            _isCategoryTreeRequest(request) ||
            _isSingleCategoryRequest(request),
      );

  static bool needsCheckoutCubit(List<EngineMappedRequest> requests) =>
      requests.any(_isPaymentMethodsRequest);

  static bool needsOrderCubit(List<EngineMappedRequest> requests) =>
      requests.any(_isCustomerOrdersListRequest) ||
      requests.any(_isCustomerOrderDetailRequest) ||
      requests.any(_isShipmentTrackRequest);

  static bool _isPaymentMethodsRequest(EngineMappedRequest request) {
    final url = request.requestUrl?.toLowerCase() ?? '';
    return url.contains('/public/payments/methods');
  }

  /// URL candidates for classifying a mapped request (resolved + declared templates).
  static Iterable<String> requestUrlCandidates(EngineMappedRequest request) sync* {
    for (final url in [
      request.requestUrl,
      request.rawRequestUrl,
      request.fallbackRequestUrl,
    ]) {
      if (url != null && url.isNotEmpty) {
        yield url.toLowerCase();
      }
    }
  }

  static bool _urlMatchesAny(
    EngineMappedRequest request,
    bool Function(String url) predicate,
  ) {
    for (final url in requestUrlCandidates(request)) {
      if (predicate(url)) {
        return true;
      }
    }
    return false;
  }

  static List<EngineMappedRequest> collectRequests(
    ScreenConfig config, {
    Map<String, String> routeParams = const {},
    Map<String, String> queryParams = const {},
  }) {
    final mapped = <EngineMappedRequest>[];
    _collectFromNode(
      config.root,
      mapped,
      routeParams: routeParams,
      queryParams: queryParams,
    );
    AppLogger.debug('[RequestMapper] collected requests: ${mapped.length}');
    return mapped;
  }

  /// Resolves `:param` placeholders in [url] using route, query, and page state.
  static String? resolveRequestUrl(
    String? url, {
    Map<String, String> routeParams = const {},
    Map<String, String> queryParams = const {},
    Map<String, dynamic> pageState = const {},
    Map<String, dynamic>? pathBindings,
    String? Function(String fieldId)? formValueFor,
  }) {
    if (url == null || url.isEmpty) {
      return url;
    }

    var resolved = url.replaceAllMapped(RegExp(r':([A-Za-z0-9_]+)'), (match) {
      final key = match.group(1) ?? '';
      final fromRoute = routeParams[key];
      if (fromRoute != null && fromRoute.isNotEmpty) {
        return fromRoute;
      }
      if (key == 'slug') {
        final slug = routeParams['productId'] ?? routeParams['categorySlug'];
        if (slug != null && slug.isNotEmpty) {
          return slug;
        }
      }
      final fromQuery = queryParams[key];
      if (fromQuery != null && fromQuery.isNotEmpty) {
        return fromQuery;
      }
      return match.group(0) ?? '';
    });

    if (pathBindings != null && pathBindings.isNotEmpty) {
      final withPath = _applyPathBindings(
        resolved,
        bindings: pathBindings,
        pageState: pageState,
        formValueFor: formValueFor,
      );
      if (withPath == null) {
        return null;
      }
      resolved = withPath;
    }

    if (resolved.contains(':')) {
      return null;
    }

    return resolved;
  }

  static bool _hasActiveQueryBinding({
    Map<String, dynamic> pageState = const {},
    Map<String, dynamic>? bindings,
    String? Function(String fieldId)? formValueFor,
  }) {
    if (bindings == null || bindings.isEmpty) {
      return false;
    }
    for (final spec in bindings.values) {
      final value = _resolveBindingValue(
        spec,
        pageState: pageState,
        formValueFor: formValueFor,
      );
      if (value != null && value.toString().trim().isNotEmpty) {
        return true;
      }
    }
    return false;
  }

  static String? _resolveInitialRequestUrl({
    required String? requestUrl,
    required String? fallbackRequestUrl,
    required Map<String, dynamic>? queryBindings,
    required Map<String, dynamic>? pathBindings,
  }) {
    if (fallbackRequestUrl != null &&
        fallbackRequestUrl.isNotEmpty &&
        queryBindings != null &&
        queryBindings.isNotEmpty &&
        !_hasActiveQueryBinding(bindings: queryBindings)) {
      return fallbackRequestUrl;
    }
    if ((requestUrl == null || requestUrl.isEmpty) &&
        fallbackRequestUrl != null &&
        fallbackRequestUrl.isNotEmpty) {
      return fallbackRequestUrl;
    }
    return requestUrl;
  }

  /// Rebuilds [base] with runtime [pageState], [pathBindings], and [queryBindings].
  static EngineMappedRequest buildRuntimeRequest(
    EngineMappedRequest base, {
    Map<String, dynamic> pageState = const {},
    Map<String, String> routeParams = const {},
    Map<String, String> queryParams = const {},
    String? Function(String fieldId)? formValueFor,
  }) {
    final template = base.rawRequestUrl ?? base.requestUrl;
    var resolved = resolveRequestUrl(
      template,
      routeParams: routeParams,
      queryParams: queryParams,
      pageState: pageState,
      pathBindings: base.pathBindings,
      formValueFor: formValueFor,
    );
    if (resolved == null || resolved.isEmpty || resolved.contains(':')) {
      final fallback = base.fallbackRequestUrl;
      if (fallback != null && fallback.isNotEmpty) {
        resolved = fallback;
      } else {
        return EngineMappedRequest(
          key: base.key,
          requestUrl: null,
          rawRequestUrl: base.rawRequestUrl ?? base.requestUrl,
          semanticType: base.semanticType,
          page: base.page,
          size: base.size,
          sort: base.sort,
          q: base.q,
          categoryId: base.categoryId,
          tagId: base.tagId,
          minPrice: base.minPrice,
          maxPrice: base.maxPrice,
          inStockOnly: base.inStockOnly,
          include: base.include,
          qField: base.qField,
          queryBindings: base.queryBindings,
          pathBindings: base.pathBindings,
          deferInitialDispatch: base.deferInitialDispatch,
          primeFromRequest: base.primeFromRequest,
          fallbackRequestUrl: base.fallbackRequestUrl,
          sourceData: base.sourceData,
        );
      }
    }

    if (base.fallbackRequestUrl != null &&
        base.fallbackRequestUrl!.isNotEmpty &&
        base.queryBindings != null &&
        base.queryBindings!.isNotEmpty &&
        !_hasActiveQueryBinding(
          pageState: pageState,
          bindings: base.queryBindings,
          formValueFor: formValueFor,
        )) {
      resolved = base.fallbackRequestUrl;
    }

    if (resolved == null || resolved.isEmpty) {
      return EngineMappedRequest(
        key: base.key,
        requestUrl: null,
        rawRequestUrl: base.rawRequestUrl ?? base.requestUrl,
        semanticType: base.semanticType,
        page: base.page,
        size: base.size,
        sort: base.sort,
        q: base.q,
        categoryId: base.categoryId,
        tagId: base.tagId,
        minPrice: base.minPrice,
        maxPrice: base.maxPrice,
        inStockOnly: base.inStockOnly,
        include: base.include,
        qField: base.qField,
        queryBindings: base.queryBindings,
        pathBindings: base.pathBindings,
        deferInitialDispatch: base.deferInitialDispatch,
        primeFromRequest: base.primeFromRequest,
        fallbackRequestUrl: base.fallbackRequestUrl,
        sourceData: base.sourceData,
      );
    }

    resolved = _applyQueryBindings(
      resolved,
      bindings: base.queryBindings,
      pageState: pageState,
      formValueFor: formValueFor,
    );

    final listQuery = _parseListQuery(resolved, base.sourceData);
    final searchQuery = _parseSearchQuery(resolved, base.sourceData);
    final include = _parseInclude(resolved, base.sourceData);

    return EngineMappedRequest(
      key: base.key,
      requestUrl: resolved,
      rawRequestUrl: base.rawRequestUrl ?? base.requestUrl,
      semanticType: base.semanticType,
      page: listQuery.$1,
      size: listQuery.$2,
      sort: listQuery.$3 ?? searchQuery.sort,
      q: _resolveQuery(base, formValueFor) ?? searchQuery.q,
      categoryId: searchQuery.categoryId,
      tagId: searchQuery.tagId,
      minPrice: searchQuery.minPrice,
      maxPrice: searchQuery.maxPrice,
      inStockOnly: searchQuery.inStockOnly,
      include: include,
      qField: base.qField,
      queryBindings: base.queryBindings,
      pathBindings: base.pathBindings,
      deferInitialDispatch: base.deferInitialDispatch,
      primeFromRequest: base.primeFromRequest,
      fallbackRequestUrl: base.fallbackRequestUrl,
      sourceData: base.sourceData,
    );
  }

  static String? _applyPathBindings(
    String url, {
    Map<String, dynamic>? bindings,
    Map<String, dynamic> pageState = const {},
    String? Function(String fieldId)? formValueFor,
  }) {
    if (bindings == null || bindings.isEmpty) {
      return url;
    }

    var resolved = url;
    for (final entry in bindings.entries) {
      final placeholder = entry.key.startsWith(':')
          ? entry.key
          : ':${entry.key}';
      final value = _resolveBindingValue(
        entry.value,
        pageState: pageState,
        formValueFor: formValueFor,
      );
      final text = value?.toString().trim() ?? '';
      if (text.isEmpty) {
        continue;
      }
      resolved = resolved.replaceAll(placeholder, text);
    }

    if (resolved.contains(':')) {
      return null;
    }
    return resolved;
  }

  static String _applyQueryBindings(
    String url, {
    Map<String, dynamic>? bindings,
    Map<String, dynamic> pageState = const {},
    String? Function(String fieldId)? formValueFor,
  }) {
    if (bindings == null || bindings.isEmpty) {
      return url;
    }

    final uri = Uri.parse(url);
    final params = Map<String, String>.from(uri.queryParameters);

    for (final entry in bindings.entries) {
      final paramName = entry.key;
      final spec = entry.value;
      final value = _resolveBindingValue(
        spec,
        pageState: pageState,
        formValueFor: formValueFor,
      );
      final text = value?.toString().trim() ?? '';
      if (text.isEmpty) {
        params.remove(paramName);
      } else {
        params[paramName] = text;
      }
    }

    return uri.replace(queryParameters: params).toString();
  }

  static dynamic _resolveBindingValue(
    dynamic spec, {
    Map<String, dynamic> pageState = const {},
    String? Function(String fieldId)? formValueFor,
  }) {
    if (spec == null) {
      return null;
    }
    if (spec is! Map) {
      final text = spec.toString().trim();
      return text.isEmpty ? null : text;
    }

    final source = (spec['source'] as String?)?.toLowerCase();
    final field = spec['field'] as String?;
    switch (source) {
      case 'pagestate':
      case 'page_state':
        if (field != null && field.isNotEmpty) {
          return pageState[field];
        }
        return null;
      case 'form':
        if (field != null && formValueFor != null) {
          return formValueFor(field);
        }
        return null;
      case 'value':
        return spec['value'];
      default:
        return spec['value'];
    }
  }

  static Future<void> dispatchRequests({
    ProductCubit? productCubit,
    ProductSearchCubit? productSearchCubit,
    ProductAutocompleteCubit? productAutocompleteCubit,
    ProductDetailCubit? productDetailCubit,
    CategoryCubit? categoryCubit,
    CheckoutCubit? checkoutCubit,
    OrderCubit? orderCubit,
    required String? tenantId,
    required List<EngineMappedRequest> requests,
    String? Function(String fieldId)? formValueFor,
  }) async {
    if (requests.isEmpty) return;

    if (tenantId != null && tenantId.isNotEmpty) {
      productCubit?.setTenantId(tenantId);
      productSearchCubit?.setTenantId(tenantId);
      productAutocompleteCubit?.setTenantId(tenantId);
      productDetailCubit?.setTenantId(tenantId);
      categoryCubit?.setTenantId(tenantId);
      checkoutCubit?.setTenantId(tenantId);
      orderCubit?.setTenantId(tenantId);
    }

    for (final request in requests) {
      if (_isCustomerOrdersListRequest(request)) {
        if (orderCubit == null) continue;
        final status = _parseOrderStatusQuery(request.requestUrl);
        AppLogger.debug(
          '[RequestMapper] dispatch orders list key=${request.key} '
          'url=${request.requestUrl} page=${request.page} size=${request.size} '
          'tenant=${tenantId ?? "not_set"}',
        );
        await orderCubit.loadOrders(
          request.key,
          page: request.page,
          size: request.size,
          status: status,
        );
        continue;
      }

      if (_isCustomerOrderDetailRequest(request)) {
        if (orderCubit == null) continue;
        final orderId = _parseOrderId(request.requestUrl);
        if (orderId == null || orderId.isEmpty) {
          continue;
        }
        AppLogger.debug(
          '[RequestMapper] dispatch order detail key=${request.key} '
          'orderId=$orderId url=${request.requestUrl} '
          'tenant=${tenantId ?? "not_set"}',
        );
        await orderCubit.loadOrderDetail(
          requestKey: request.key,
          orderId: orderId,
        );
        continue;
      }

      if (_isShipmentTrackRequest(request)) {
        if (orderCubit == null) continue;
        final orderId = _parseOrderId(request.requestUrl);
        if (orderId == null || orderId.isEmpty) {
          continue;
        }
        AppLogger.debug(
          '[RequestMapper] dispatch shipment track key=${request.key} '
          'orderId=$orderId url=${request.requestUrl} '
          'tenant=${tenantId ?? "not_set"}',
        );
        await orderCubit.loadShipmentTrack(
          requestKey: request.key,
          orderId: orderId,
        );
        continue;
      }

      if (_isPaymentMethodsRequest(request)) {
        if (checkoutCubit == null) continue;
        AppLogger.debug(
          '[RequestMapper] dispatch payment methods key=${request.key} '
          'url=${request.requestUrl} tenant=${tenantId ?? "not_set"}',
        );
        await checkoutCubit.loadPaymentMethods(request.key);
        continue;
      }

      if (_isCategoryProductsRequest(request)) {
        if (productCubit == null) continue;
        final slug = _parseCategorySlug(request.requestUrl);
        if (slug == null || slug.isEmpty) {
          continue;
        }

        AppLogger.debug(
          '[RequestMapper] dispatch category products key=${request.key} '
          'slug=$slug url=${request.requestUrl} page=${request.page} '
          'size=${request.size} tenant=${tenantId ?? "not_set"}',
        );
        await productCubit.getCategoryProducts(
          categorySlug: slug,
          page: request.page,
          size: request.size,
          sort: request.sort,
          requestKey: request.key,
        );
        continue;
      }

      if (_isBrowseProductsRequest(request)) {
        if (productCubit == null) continue;
        AppLogger.debug(
          '[RequestMapper] dispatch browse products key=${request.key} '
          'url=${request.requestUrl} page=${request.page} size=${request.size} '
          'tenant=${tenantId ?? "not_set"}',
        );
        await productCubit.getProducts(
          page: request.page,
          size: request.size,
          sort: request.sort,
          requestKey: request.key,
        );
        continue;
      }

      if (_isSearchRequest(request)) {
        if (productSearchCubit == null) continue;
        final q = _resolveQuery(request, formValueFor);
        final hasCategoryFilter =
            request.categoryId != null && request.categoryId!.isNotEmpty;
        if ((q == null || q.isEmpty) && !hasCategoryFilter) {
          continue;
        }
        AppLogger.debug(
          '[RequestMapper] dispatch search key=${request.key} '
          'url=${request.requestUrl} q=${q ?? ''} '
          'categoryId=${request.categoryId ?? ''} '
          'tenant=${tenantId ?? "not_set"}',
        );
        productSearchCubit.search(
          q: q ?? '',
          categoryId: request.categoryId,
          tagId: request.tagId,
          minPrice: request.minPrice,
          maxPrice: request.maxPrice,
          inStockOnly: request.inStockOnly,
          page: request.page,
          size: request.size,
          sort: request.sort,
          requestKey: request.key,
        );
        continue;
      }

      if (_isAutocompleteRequest(request)) {
        if (productAutocompleteCubit == null) continue;
        final q = _resolveQuery(request, formValueFor);
        if (q == null || q.trim().length < 3) {
          continue;
        }
        AppLogger.debug(
          '[RequestMapper] dispatch autocomplete key=${request.key} '
          'url=${request.requestUrl} q=$q '
          'tenant=${tenantId ?? "not_set"}',
        );
        productAutocompleteCubit.fetchSuggestions(
          q,
          requestKey: request.key,
        );
        continue;
      }

      if (_isProductDetailRequest(request)) {
        if (productDetailCubit == null) continue;
        final slug = _parseProductSlug(request.requestUrl);
        if (slug == null || slug.isEmpty) {
          continue;
        }

        AppLogger.debug(
          '[RequestMapper] dispatch product detail key=${request.key} '
          'slug=$slug url=${request.requestUrl} '
          'tenant=${tenantId ?? "not_set"}',
        );
        await productDetailCubit.loadDetail(
          slug,
          include: request.include,
          requestKey: request.key,
        );
        continue;
      }

      if (_isCategoryTreeRequest(request)) {
        if (categoryCubit == null) continue;
        AppLogger.debug(
          '[RequestMapper] dispatch category tree key=${request.key} '
          'url=${request.requestUrl} tenant=${tenantId ?? "not_set"}',
        );
        await categoryCubit.loadTree(requestKey: request.key);
        continue;
      }

      if (_isSingleCategoryRequest(request)) {
        if (categoryCubit == null) continue;
        final slug = _parseCategoryNavSlug(request.requestUrl);
        if (slug == null || slug.isEmpty) {
          continue;
        }

        AppLogger.debug(
          '[RequestMapper] dispatch category key=${request.key} '
          'slug=$slug url=${request.requestUrl} '
          'tenant=${tenantId ?? "not_set"}',
        );
        await categoryCubit.loadCategory(slug, requestKey: request.key);
      }
    }
  }

  static String? _resolveQuery(
    EngineMappedRequest request,
    String? Function(String fieldId)? formValueFor,
  ) {
    if (request.qField != null && formValueFor != null) {
      final fromForm = formValueFor(request.qField!)?.trim();
      if (fromForm != null && fromForm.isNotEmpty) {
        return fromForm;
      }
    }
    return request.q?.trim();
  }

  static void _collectFromNode(
    ComponentConfig node,
    List<EngineMappedRequest> collector, {
    Map<String, String> routeParams = const {},
    Map<String, String> queryParams = const {},
  }) {
    final mapped = _buildMappedRequest(
      node,
      routeParams: routeParams,
      queryParams: queryParams,
    );
    if (mapped != null) {
      collector.add(mapped);
    }

    final child = node.child;
    if (child != null) {
      _collectFromNode(
        child,
        collector,
        routeParams: routeParams,
        queryParams: queryParams,
      );
    }

    final children = node.children;
    if (children != null) {
      for (final entry in children) {
        _collectFromNode(
          entry,
          collector,
          routeParams: routeParams,
          queryParams: queryParams,
        );
      }
    }
  }

  static EngineMappedRequest? _buildMappedRequest(
    ComponentConfig node, {
    Map<String, String> routeParams = const {},
    Map<String, String> queryParams = const {},
  }) {
    final semanticType = node.properties['semanticType'] as String?;
    final data = node.properties['data'];
    if (data is! Map<String, dynamic>) {
      return null;
    }

    final rawRequestUrl = data['requestUrl'] as String?;
    final requestUrl = resolveRequestUrl(
      rawRequestUrl,
      routeParams: routeParams,
      queryParams: queryParams,
    );
    final explicitKey =
        data['requestKey'] as String? ?? data['requestId'] as String?;
    final nodeId = node.properties['id'] as String?;
    final qField = data['qField'] as String?;
    final queryBindings = data['queryBindings'] is Map
        ? Map<String, dynamic>.from(data['queryBindings'] as Map)
        : null;
    final pathBindings = data['pathBindings'] is Map
        ? Map<String, dynamic>.from(data['pathBindings'] as Map)
        : null;
    final primeFromRequest = EnginePrimeFromRequest.fromData(
      data['primeFromRequest'] is Map
          ? Map<String, dynamic>.from(data['primeFromRequest'] as Map)
          : null,
    );
    final fallbackRequestUrl = data['fallbackRequestUrl'] as String?;
    final deferInitialDispatch = pathBindings != null &&
        pathBindings.isNotEmpty &&
        rawRequestUrl != null &&
        rawRequestUrl.contains(':') &&
        (requestUrl == null || requestUrl.isEmpty) &&
        (fallbackRequestUrl == null || fallbackRequestUrl.isEmpty);

    if ((requestUrl == null || requestUrl.isEmpty) &&
        rawRequestUrl == null &&
        explicitKey == null) {
      return null;
    }

    if (rawRequestUrl != null &&
        rawRequestUrl.contains(':') &&
        (requestUrl == null || requestUrl.isEmpty) &&
        (fallbackRequestUrl == null || fallbackRequestUrl.isEmpty) &&
        !deferInitialDispatch) {
      return null;
    }

    final key = explicitKey ?? requestUrl ?? semanticType ?? nodeId ??
        _defaultProductRequestKey;
    final effectiveRequestUrl = _resolveInitialRequestUrl(
      requestUrl: requestUrl,
      fallbackRequestUrl: fallbackRequestUrl,
      queryBindings: queryBindings,
      pathBindings: pathBindings,
    );
    final listQuery = _parseListQuery(
      effectiveRequestUrl ?? rawRequestUrl,
      data,
    );
    final searchQuery = _parseSearchQuery(
      effectiveRequestUrl ?? rawRequestUrl,
      data,
    );
    final include = _parseInclude(effectiveRequestUrl ?? rawRequestUrl, data);

    return EngineMappedRequest(
      key: key,
      requestUrl: effectiveRequestUrl,
      rawRequestUrl: rawRequestUrl,
      semanticType: semanticType,
      page: listQuery.$1,
      size: listQuery.$2,
      sort: listQuery.$3 ?? searchQuery.sort,
      q: searchQuery.q,
      categoryId: searchQuery.categoryId,
      tagId: searchQuery.tagId,
      minPrice: searchQuery.minPrice,
      maxPrice: searchQuery.maxPrice,
      inStockOnly: searchQuery.inStockOnly,
      include: include,
      qField: qField,
      queryBindings: queryBindings,
      pathBindings: pathBindings,
      deferInitialDispatch: deferInitialDispatch,
      primeFromRequest: primeFromRequest,
      fallbackRequestUrl: fallbackRequestUrl,
      sourceData: Map<String, dynamic>.from(data),
    );
  }

  static bool _isBrowseProductsRequest(EngineMappedRequest request) {
    if (_isProductDetailRequest(request)) {
      return false;
    }
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
    final url = request.requestUrl?.toLowerCase() ??
        request.rawRequestUrl?.toLowerCase() ??
        '';
    if (url.isEmpty) {
      return false;
    }
    return _categoryProductsPattern.hasMatch(url);
  }

  static bool _isSearchRequest(EngineMappedRequest request) {
    return _urlMatchesAny(
      request,
      (url) => url.contains('/public/products/search'),
    );
  }

  static bool _isAutocompleteRequest(EngineMappedRequest request) {
    return _urlMatchesAny(
      request,
      (url) => url.contains('/public/products/autocomplete'),
    );
  }

  static bool _isProductDetailRequest(EngineMappedRequest request) {
    final url = request.requestUrl?.toLowerCase() ?? '';
    if (url.isEmpty || !url.contains('/public/products/')) {
      return false;
    }
    if (url.contains('/search') || url.contains('/autocomplete')) {
      return false;
    }

    final uri = Uri.tryParse(url);
    if (uri == null) {
      return !url.endsWith('/products') && !url.endsWith('/products/');
    }

    final segments = uri.pathSegments;
    final productsIndex = segments.lastIndexOf('products');
    if (productsIndex < 0 || productsIndex >= segments.length - 1) {
      return false;
    }

    final slug = segments[productsIndex + 1];
    return slug.isNotEmpty &&
        slug != 'search' &&
        slug != 'autocomplete';
  }

  static bool _isCategoryTreeRequest(EngineMappedRequest request) {
    final url = request.requestUrl?.toLowerCase() ?? '';
    if (url.isEmpty) {
      return false;
    }

    final uri = Uri.tryParse(url);
    if (uri == null) {
      return url.endsWith('/public/categories') ||
          url.endsWith('/public/categories/');
    }

    return uri.path == '/api/v1/public/categories' ||
        uri.path == '/public/categories';
  }

  static bool _isSingleCategoryRequest(EngineMappedRequest request) {
    if (_isCategoryTreeRequest(request) ||
        _isCategoryProductsRequest(request)) {
      return false;
    }

    final url = request.requestUrl?.toLowerCase() ?? '';
    if (url.isEmpty || !url.contains('/public/categories/')) {
      return false;
    }
    if (url.contains('/products')) {
      return false;
    }

    final slug = _parseCategoryNavSlug(request.requestUrl);
    return slug != null && slug.isNotEmpty;
  }

  static String? _parseProductSlug(String? requestUrl) {
    if (requestUrl == null || requestUrl.isEmpty) {
      return null;
    }

    final uri = Uri.tryParse(requestUrl);
    if (uri == null) {
      return null;
    }

    final segments = uri.pathSegments;
    final productsIndex = segments.lastIndexOf('products');
    if (productsIndex < 0 || productsIndex >= segments.length - 1) {
      return null;
    }

    return segments[productsIndex + 1];
  }

  static String? _parseCategoryNavSlug(String? requestUrl) {
    if (requestUrl == null || requestUrl.isEmpty) {
      return null;
    }

    final uri = Uri.tryParse(requestUrl);
    if (uri == null) {
      return null;
    }

    final segments = uri.pathSegments;
    final categoriesIndex = segments.lastIndexOf('categories');
    if (categoriesIndex < 0 ||
        categoriesIndex >= segments.length - 1) {
      return null;
    }

    final slug = segments[categoriesIndex + 1];
    if (slug == 'products') {
      return null;
    }

    return slug;
  }

  static String? _parseInclude(String? requestUrl, Map<String, dynamic> data) {
    final fromData = data['include'] as String?;
    if (fromData != null && fromData.isNotEmpty) {
      return fromData;
    }

    if (requestUrl == null || requestUrl.isEmpty) {
      return null;
    }

    final uri = Uri.tryParse(requestUrl);
    final fromQuery = uri?.queryParameters['include'];
    if (fromQuery != null && fromQuery.isNotEmpty) {
      return fromQuery;
    }

    return null;
  }

  static String? _parseCategorySlug(String? requestUrl) {
    if (requestUrl == null || requestUrl.isEmpty) {
      return null;
    }
    return _categoryProductsPattern.firstMatch(requestUrl)?.group(1);
  }

  static bool _isCustomerOrdersListRequest(EngineMappedRequest request) {
    final url = request.requestUrl?.toLowerCase() ?? '';
    if (url.isEmpty || !url.contains('/customer/orders')) {
      return false;
    }
    if (url.contains('/cancel') || url.contains('/invoice')) {
      return false;
    }
    return _parseOrderId(request.requestUrl) == null;
  }

  static bool _isCustomerOrderDetailRequest(EngineMappedRequest request) {
    final url = request.requestUrl?.toLowerCase() ?? '';
    if (url.isEmpty || !url.contains('/customer/orders/')) {
      return false;
    }
    if (url.contains('/cancel') || url.contains('/invoice')) {
      return false;
    }
    return _parseOrderId(request.requestUrl) != null;
  }

  static bool _isShipmentTrackRequest(EngineMappedRequest request) {
    final url = request.requestUrl?.toLowerCase() ?? '';
    return url.contains('/public/shipping/track/');
  }

  static String? _parseOrderId(String? requestUrl) {
    if (requestUrl == null || requestUrl.isEmpty) {
      return null;
    }

    final uri = Uri.tryParse(requestUrl);
    if (uri == null) {
      return null;
    }

    final segments = uri.pathSegments;
    final ordersIndex = segments.lastIndexOf('orders');
    if (ordersIndex >= 0 && ordersIndex < segments.length - 1) {
      final id = segments[ordersIndex + 1];
      if (id.isNotEmpty && id != 'cancel' && id != 'invoice') {
        return id;
      }
    }

    final trackIndex = segments.lastIndexOf('track');
    if (trackIndex >= 0 && trackIndex < segments.length - 1) {
      final id = segments[trackIndex + 1];
      if (id.isNotEmpty) {
        return id;
      }
    }

    return null;
  }

  static String? _parseOrderStatusQuery(String? requestUrl) {
    if (requestUrl == null || requestUrl.isEmpty) {
      return null;
    }
    final uri = Uri.tryParse(requestUrl);
    final status = uri?.queryParameters['status'];
    if (status == null || status.isEmpty) {
      return null;
    }
    return status;
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

  static ({
    String? q,
    String? categoryId,
    String? tagId,
    double? minPrice,
    double? maxPrice,
    bool? inStockOnly,
    String? sort,
  }) _parseSearchQuery(String? requestUrl, Map<String, dynamic> data) {
    String? q = data['q'] as String?;
    String? categoryId = data['categoryId'] as String?;
    String? tagId = data['tagId'] as String?;
    double? minPrice = (data['minPrice'] as num?)?.toDouble();
    double? maxPrice = (data['maxPrice'] as num?)?.toDouble();
    bool? inStockOnly = data['inStockOnly'] as bool?;
    String? sort = data['sort'] as String?;

    if (requestUrl == null || requestUrl.isEmpty) {
      return (
        q: q,
        categoryId: categoryId,
        tagId: tagId,
        minPrice: minPrice,
        maxPrice: maxPrice,
        inStockOnly: inStockOnly,
        sort: sort,
      );
    }

    final uri = Uri.tryParse(requestUrl);
    if (uri == null) {
      return (
        q: q,
        categoryId: categoryId,
        tagId: tagId,
        minPrice: minPrice,
        maxPrice: maxPrice,
        inStockOnly: inStockOnly,
        sort: sort,
      );
    }

    final params = uri.queryParameters;
    q = params['q']?.isNotEmpty == true ? params['q'] : q;
    categoryId =
        params['categoryId']?.isNotEmpty == true ? params['categoryId'] : categoryId;
    tagId = params['tagId']?.isNotEmpty == true ? params['tagId'] : tagId;
    minPrice ??= double.tryParse(params['minPrice'] ?? '');
    maxPrice ??= double.tryParse(params['maxPrice'] ?? '');
    if (params.containsKey('inStockOnly')) {
      inStockOnly ??= params['inStockOnly'] == 'true';
    }
    sort = params['sort']?.isNotEmpty == true ? params['sort'] : sort;

    return (
      q: q,
      categoryId: categoryId,
      tagId: tagId,
      minPrice: minPrice,
      maxPrice: maxPrice,
      inStockOnly: inStockOnly,
      sort: sort,
    );
  }
}
