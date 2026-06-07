import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sooq_merchant/core/cubits/token_cubit/token_cubit.dart';
import 'package:sooq_merchant/core/network/network_config.dart';
import 'package:sooq_merchant/core/network/tenant_resolver.dart';
import 'package:sooq_merchant/core/feedback/app_messenger.dart';

import 'package:sooq_merchant/config/mobile_app_config.dart';
import 'package:sooq_merchant/core/utils/service_locator.dart';
import 'package:sooq_merchant/core/utils/syp_formatter.dart';
import 'package:sooq_merchant/features/commerce/cart/presentation/manager/cart_cubit/cart_cubit.dart';
import 'package:sooq_merchant/features/commerce/cart/presentation/manager/cart_cubit/cart_state.dart';
import 'package:sooq_merchant/features/commerce/checkout/presentation/manager/checkout_cubit/checkout_cubit.dart';
import 'package:sooq_merchant/features/commerce/checkout/presentation/manager/checkout_cubit/checkout_state.dart';
import 'package:sooq_merchant/features/commerce/data/models/customer_order.dart';
import 'package:sooq_merchant/features/commerce/data/models/customer_shipment_status.dart';
import 'package:sooq_merchant/features/commerce/data/models/enums/order_status.dart';
import 'package:sooq_merchant/features/commerce/data/models/order_list_response.dart';
import 'package:sooq_merchant/features/commerce/data/models/public_payment_method.dart';
import 'package:sooq_merchant/features/commerce/order/presentation/manager/order_cubit/order_cubit.dart';
import 'package:sooq_merchant/features/commerce/order/presentation/manager/order_cubit/order_state.dart';
import 'package:sooq_merchant/engine/actions/action_dispatcher.dart';
import 'package:sooq_merchant/engine/form/form_state_store.dart';
import 'package:sooq_merchant/engine/requests/request_mapper.dart';
import 'package:sooq_merchant/engine/theme/engine_theme.dart';
import 'package:sooq_merchant/engine/tree/tree_engine.dart';
import 'package:sooq_merchant/features/auth/presentation/manager/auth_cubit/auth_cubit.dart';
import 'package:sooq_merchant/features/product/data/models/category.dart';
import 'package:sooq_merchant/features/product/data/models/product_autocomplete_result.dart';
import 'package:sooq_merchant/features/product/data/models/product_detail.dart';
import 'package:sooq_merchant/features/product/data/models/product_list_response.dart';
import 'package:sooq_merchant/features/product/data/models/product_search_result.dart';
import 'package:sooq_merchant/features/product/presentation/manager/category_cubit/category_cubit.dart';
import 'package:sooq_merchant/features/product/presentation/manager/product_autocomplete_cubit/product_autocomplete_cubit.dart';
import 'package:sooq_merchant/features/product/presentation/manager/product_cubit/product_cubit.dart';
import 'package:sooq_merchant/features/product/presentation/manager/product_detail_cubit/product_detail_cubit.dart';
import 'package:sooq_merchant/features/product/presentation/manager/product_search_cubit/product_search_cubit.dart';
import 'package:sooq_merchant/features/variantscreen/data/repos/variant_repository.dart';
import 'package:sooq_merchant/features/variantscreen/presentation/manager/variant_cubit/variant_cubit.dart';

/// Dynamic screen host widget.
class VariantScreen extends StatefulWidget {
  const VariantScreen({
    super.key,
    required this.variantId,
    required this.variantRepository,
    this.pageRoute,
    this.routeParams = const {},
    this.queryParams = const {},
    this.mobileAppConfig,
  });

  final String variantId;
  final VariantRepository variantRepository;
  final String? pageRoute;
  final Map<String, String> routeParams;
  final Map<String, String> queryParams;
  final MobileAppConfig? mobileAppConfig;

  @override
  State<VariantScreen> createState() => _VariantScreenState();
}

class _VariantScreenState extends State<VariantScreen> {
  late final FormStateStore _formStateStore;
  late final Map<String, dynamic> _dataContext;
  final Map<String, dynamic> _requestResults = <String, dynamic>{};
  final Set<String> _loadingRequestKeys = <String>{};
  final Set<String> _loadingMoreRequestKeys = <String>{};
  String? _primedPageSignature;

  static const _authRoutes = {'/auth/login', '/auth/otp-reset'};

  static const _splashRoutes = {'/splash', '/splash-carousel'};

  static const _checkoutRoutes = {
    '/checkout',
    '/checkout/address',
    '/checkout/payment',
    '/order/success',
    '/order/failure',
  };

  static final _orderDetailRoutePattern = RegExp(r'^/orders/[^/]+$');

  bool get _isAuthRoute =>
      widget.pageRoute != null && _authRoutes.contains(widget.pageRoute);

  bool get _isCheckoutRoute =>
      widget.pageRoute != null && _checkoutRoutes.contains(widget.pageRoute);

  bool get _isOrderRoute =>
      widget.pageRoute != null &&
      (widget.pageRoute == '/orders' ||
          widget.pageRoute == '/orders/track' ||
          _orderDetailRoutePattern.hasMatch(widget.pageRoute!));

  bool get _isSplashRoute =>
      widget.pageRoute != null && _splashRoutes.contains(widget.pageRoute);

  @override
  void initState() {
    super.initState();
    _formStateStore = FormStateStore();
    _dataContext = {FormStateStore.contextKey: _formStateStore};
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final dispatcher = EngineActionDispatcher(
      context: context,
      formState: _formStateStore,
      dataContext: _buildRenderContext(),
    );
    _dataContext[EngineActionDispatcher.contextKey] = dispatcher;
  }

  @override
  void dispose() {
    _formStateStore.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<VariantCubit>(
      key: ValueKey(
        '${widget.variantId}:${widget.pageRoute ?? ''}:${widget.routeParams}',
      ),
      create: (_) => VariantCubit(
        widget.variantRepository,
        widget.variantId,
        pageRoute: widget.pageRoute,
      ),
      child: BlocBuilder<VariantCubit, VariantState>(
        builder: (context, state) {
          return switch (state) {
            VariantInitial() || VariantLoading() => const Center(
              child: CircularProgressIndicator(),
            ),
            VariantSuccess(:final config) => _buildSuccessView(config),
            VariantFailure(:final message) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ),
          };
        },
      ),
    );
  }

  Widget _buildSuccessView(dynamic config) {
    final mappedRequests = EngineRequestMapper.collectRequests(
      config,
      routeParams: widget.routeParams,
      queryParams: widget.queryParams,
    );
    final pageRequestKeys = mappedRequests
        .where((request) => request.qField == null)
        .map((request) => request.key)
        .toSet();
    _ensurePageRequestsPrimed(pageRequestKeys);
    final renderContext = _buildRenderContext(mappedRequests: mappedRequests);

    final providers = <BlocProvider>[
      if (EngineRequestMapper.needsProductCubit(mappedRequests))
        BlocProvider<ProductCubit>(create: (_) => getIt<ProductCubit>()),
      if (EngineRequestMapper.needsSearchCubit(mappedRequests))
        BlocProvider<ProductSearchCubit>(
          create: (_) => getIt<ProductSearchCubit>(),
        ),
      if (EngineRequestMapper.needsAutocompleteCubit(mappedRequests))
        BlocProvider<ProductAutocompleteCubit>(
          create: (_) => getIt<ProductAutocompleteCubit>(),
        ),
      if (EngineRequestMapper.needsProductDetailCubit(mappedRequests))
        BlocProvider<ProductDetailCubit>(
          create: (_) => getIt<ProductDetailCubit>(),
        ),
      if (EngineRequestMapper.needsCategoryCubit(mappedRequests))
        BlocProvider<CategoryCubit>(create: (_) => getIt<CategoryCubit>()),
      if (EngineRequestMapper.needsCheckoutCubit(mappedRequests))
        BlocProvider<CheckoutCubit>.value(value: getIt<CheckoutCubit>()),
      if (EngineRequestMapper.needsOrderCubit(mappedRequests))
        BlocProvider<OrderCubit>.value(value: getIt<OrderCubit>()),
    ];

    Widget buildContent(Map<String, dynamic> ctx) {
      if (mappedRequests.isEmpty) {
        return ScreenRenderer.withPrimitives().render(
          config,
          context: context,
          dataContext: ctx,
        );
      }
      return MultiBlocProvider(
        providers: providers,
        child: _ProductRequestHost(
          config: config,
          mobileAppConfig: widget.mobileAppConfig,
          routeParams: widget.routeParams,
          queryParams: widget.queryParams,
          mappedRequests: mappedRequests,
          pageRequestKeys: pageRequestKeys,
          renderContext: ctx,
          formStateStore: _formStateStore,
          onPreparePageRequests: () =>
              _ensurePageRequestsPrimed(pageRequestKeys),
          onRequestLoadingChanged: _setRequestLoading,
          onProductSuccess: _handleProductSuccess,
          onProductFailure: _handleProductFailure,
          onSearchSuccess: _handleSearchSuccess,
          onSearchFailure: _handleSearchFailure,
          onAutocompleteSuccess: _handleAutocompleteSuccess,
          onAutocompleteFailure: _handleAutocompleteFailure,
          onProductDetailSuccess: _handleProductDetailSuccess,
          onProductDetailFailure: _handleProductDetailFailure,
          onCategoryTreeSuccess: _handleCategoryTreeSuccess,
          onCategorySuccess: _handleCategorySuccess,
          onCategoryFailure: _handleCategoryFailure,
          onCheckoutPaymentMethodsSuccess: _handleCheckoutPaymentMethodsSuccess,
          onCheckoutPaymentMethodsFailure: _handleCheckoutPaymentMethodsFailure,
          onOrdersListSuccess: _handleOrdersListSuccess,
          onOrdersListFailure: _handleOrdersListFailure,
          onOrderDetailSuccess: _handleOrderDetailSuccess,
          onOrderDetailFailure: _handleOrderDetailFailure,
          onShipmentTrackSuccess: _handleShipmentTrackSuccess,
          onShipmentTrackEmpty: _handleShipmentTrackEmpty,
        ),
      );
    }

    if (_isAuthRoute) {
      return BlocProvider<AuthCubit>.value(
        value: getIt<AuthCubit>(),
        child: _AuthRequestHost(
          renderContext: renderContext,
          child: buildContent(renderContext),
        ),
      );
    }

    Widget content = buildContent(renderContext);

    if (_isCheckoutRoute && getIt.isRegistered<CheckoutCubit>()) {
      content = _CheckoutRequestHost(
        renderContext: renderContext,
        child: _CheckoutHost(
          baseRenderContext: renderContext,
          childBuilder: (checkoutCtx) {
            if (!_isAuthRoute && getIt.isRegistered<CartCubit>()) {
              return _CartHost(
                baseRenderContext: checkoutCtx,
                childBuilder: buildContent,
              );
            }
            return buildContent(checkoutCtx);
          },
        ),
      );
    } else if (_isOrderRoute && getIt.isRegistered<OrderCubit>()) {
      content = _OrderRequestHost(
        renderContext: renderContext,
        child: _OrderHost(
          baseRenderContext: renderContext,
          childBuilder: buildContent,
        ),
      );
    } else if (!_isAuthRoute && getIt.isRegistered<CartCubit>()) {
      content = _CartHost(
        baseRenderContext: renderContext,
        childBuilder: buildContent,
      );
    }

    if (_isSplashRoute) {
      return _SplashSystemUiOverlay(
        pageRoute: widget.pageRoute,
        child: content,
      );
    }

    return content;
  }

  String _pageSignature() =>
      '${widget.pageRoute ?? ''}|${widget.routeParams.entries.map((e) => '${e.key}=${e.value}').join('|')}';

  void _ensurePageRequestsPrimed(Set<String> requestKeys) {
    if (requestKeys.isEmpty) {
      return;
    }
    final signature = _pageSignature();
    if (_primedPageSignature == signature) {
      return;
    }
    _primedPageSignature = signature;
    for (final key in requestKeys) {
      _requestResults.remove(key);
    }
    _loadingRequestKeys
      ..clear()
      ..addAll(requestKeys);
  }

  void _setRequestLoading(String requestKey, bool isLoading) {
    setState(() {
      if (isLoading) {
        _loadingRequestKeys.add(requestKey);
      } else {
        _loadingRequestKeys.remove(requestKey);
      }
    });
  }

  void _handleProductSuccess(
    String requestKey,
    dynamic productListResponse,
    bool isLoadMore,
  ) {
    if (!mounted) {
      return;
    }

    setState(() {
      final nextData = productListResponse.data
          .map((item) => item.toJson())
          .toList();

      _requestResults[requestKey] = {
        'success': productListResponse.success,
        'message': productListResponse.message,
        'data': nextData,
        'meta': productListResponse.meta.toJson(),
        'timestamp': productListResponse.timestamp,
      };
      if (!isLoadMore) {
        _loadingRequestKeys.remove(requestKey);
      }
      _loadingMoreRequestKeys.remove(requestKey);
    });
  }

  void _handleSearchSuccess(
    String requestKey,
    ProductSearchResult searchResult,
    bool isLoadMore,
  ) {
    if (!mounted) {
      return;
    }

    setState(() {
      _requestResults[requestKey] = {
        'success': true,
        'data': searchResult.toJson(),
      };
      if (!isLoadMore) {
        _loadingRequestKeys.remove(requestKey);
      }
      _loadingMoreRequestKeys.remove(requestKey);
    });
  }

  void _handleSearchFailure(
    String requestKey,
    String message,
    bool isLoadMore,
  ) {
    if (!mounted) {
      return;
    }

    setState(() {
      _loadingMoreRequestKeys.remove(requestKey);
      if (!isLoadMore) {
        _loadingRequestKeys.remove(requestKey);
      }
      if (isLoadMore && _requestResults[requestKey] is Map<String, dynamic>) {
        _requestResults[requestKey] = {
          ..._requestResults[requestKey] as Map<String, dynamic>,
          'loadMoreError': message,
        };
      } else {
        _requestResults[requestKey] = {
          'success': false,
          'message': message,
          'data': const <String, dynamic>{},
        };
      }
    });
  }

  void _handleAutocompleteSuccess(
    String requestKey,
    ProductAutocompleteResult autocompleteResult,
  ) {
    if (!mounted) {
      return;
    }

    setState(() {
      _requestResults[requestKey] = {
        'success': true,
        'data': autocompleteResult.toJson(),
      };
      _loadingRequestKeys.remove(requestKey);
    });
  }

  void _handleAutocompleteFailure(String requestKey, String message) {
    if (!mounted) {
      return;
    }

    setState(() {
      _requestResults[requestKey] = {
        'success': false,
        'message': message,
        'data': const <String, dynamic>{},
      };
      _loadingRequestKeys.remove(requestKey);
    });
  }

  void _handleProductDetailSuccess(String requestKey, ProductDetail detail) {
    if (!mounted) {
      return;
    }

    if (requestKey == 'product-detail' && getIt.isRegistered<CartCubit>()) {
      final prices = <String, int>{};
      for (final variant in detail.variants) {
        final id = variant.variantId?.trim();
        if (id == null || id.isEmpty) continue;
        prices[id] = parseSypAmount(variant.price) ?? 0;
      }
      getIt<CartCubit>().setVariantPriceIndex(prices);
    }

    setState(() {
      _requestResults[requestKey] = {'success': true, 'data': detail.toJson()};
      _loadingRequestKeys.remove(requestKey);
    });
  }

  void _handleProductDetailFailure(String requestKey, String message) {
    if (!mounted) {
      return;
    }

    setState(() {
      _requestResults[requestKey] = {
        'success': false,
        'message': message,
        'data': const <String, dynamic>{},
      };
      _loadingRequestKeys.remove(requestKey);
    });
  }

  void _handleCategoryTreeSuccess(
    String requestKey,
    List<Category> categories,
  ) {
    if (!mounted) {
      return;
    }

    setState(() {
      _requestResults[requestKey] = {
        'success': true,
        'data': categories.map((item) => item.toJson()).toList(),
      };
      _loadingRequestKeys.remove(requestKey);
    });
  }

  void _handleCategorySuccess(String requestKey, Category category) {
    if (!mounted) {
      return;
    }

    setState(() {
      _requestResults[requestKey] = {
        'success': true,
        'data': category.toJson(),
      };
      _loadingRequestKeys.remove(requestKey);
    });
  }

  void _handleCategoryFailure(String requestKey, String message) {
    if (!mounted) {
      return;
    }

    setState(() {
      _requestResults[requestKey] = {
        'success': false,
        'message': message,
        'data': const <String, dynamic>{},
      };
      _loadingRequestKeys.remove(requestKey);
    });
  }

  void _handleCheckoutPaymentMethodsSuccess(
    String requestKey,
    List<PublicPaymentMethod> methods,
  ) {
    if (!mounted) {
      return;
    }

    setState(() {
      _requestResults[requestKey] = {
        'success': true,
        'data': methods
            .map((method) {
              final json = Map<String, dynamic>.from(method.toJson());
              json['selectable'] = !method.requiresRedirect;
              if (method.requiresRedirect) {
                json['displayName'] = '${method.displayName} (قريباً)';
              }
              return json;
            })
            .toList(growable: false),
      };
      _loadingRequestKeys.remove(requestKey);
    });
  }

  void _handleCheckoutPaymentMethodsFailure(
    String requestKey,
    String message,
  ) {
    if (!mounted) {
      return;
    }

    setState(() {
      _requestResults[requestKey] = {
        'success': false,
        'message': message,
        'data': const <dynamic>[],
      };
      _loadingRequestKeys.remove(requestKey);
    });
  }

  void _handleOrdersListSuccess(
    String requestKey,
    OrderListResponse response,
  ) {
    if (!mounted) {
      return;
    }

    setState(() {
      _requestResults[requestKey] = {
        'success': response.success,
        'message': response.message,
        'data': response.data
            .map((row) {
              final json = Map<String, dynamic>.from(row.toJson());
              json['totalFormatted'] = formatSyp(row.total);
              json['orderStatusLabel'] = orderStatusLabel(row.orderStatus);
              return json;
            })
            .toList(growable: false),
        'meta': response.meta.toJson(),
        'timestamp': response.timestamp,
      };
      _loadingRequestKeys.remove(requestKey);
    });
  }

  void _handleOrdersListFailure(String requestKey, String message) {
    if (!mounted) {
      return;
    }

    setState(() {
      _requestResults[requestKey] = {
        'success': false,
        'message': message,
        'data': const <dynamic>[],
        'meta': const {
          'hasNext': false,
          'last': true,
          'page': 0,
          'totalPages': 0,
        },
        'timestamp': 0,
      };
      _loadingRequestKeys.remove(requestKey);
    });
  }

  void _handleOrderDetailSuccess(String requestKey, CustomerOrder order) {
    if (!mounted) {
      return;
    }

    setState(() {
      _requestResults[requestKey] = {
        'success': true,
        'data': _enrichOrderJson(order),
      };
      _loadingRequestKeys.remove(requestKey);
    });
  }

  void _handleOrderDetailFailure(String requestKey, String message) {
    if (!mounted) {
      return;
    }

    setState(() {
      _requestResults[requestKey] = {
        'success': false,
        'message': message,
        'data': const <String, dynamic>{},
      };
      _loadingRequestKeys.remove(requestKey);
    });
  }

  void _handleShipmentTrackSuccess(
    String requestKey,
    CustomerShipmentStatus shipment,
  ) {
    if (!mounted) {
      return;
    }

    setState(() {
      _requestResults[requestKey] = {
        'success': true,
        'data': shipment.toJson(),
      };
      _loadingRequestKeys.remove(requestKey);
    });
  }

  void _handleShipmentTrackEmpty(String requestKey, String message) {
    if (!mounted) {
      return;
    }

    setState(() {
      _requestResults[requestKey] = {
        'success': true,
        'data': null,
        'empty': true,
        'message': message,
      };
      _loadingRequestKeys.remove(requestKey);
    });
  }

  void _handleProductFailure(
    String requestKey,
    String message,
    bool isLoadMore,
  ) {
    if (!mounted) {
      return;
    }

    setState(() {
      _loadingMoreRequestKeys.remove(requestKey);
      if (!isLoadMore) {
        _loadingRequestKeys.remove(requestKey);
      }
      if (isLoadMore && _requestResults[requestKey] is Map<String, dynamic>) {
        _requestResults[requestKey] = {
          ..._requestResults[requestKey] as Map<String, dynamic>,
          'loadMoreError': message,
        };
      } else {
        _requestResults[requestKey] = {
          'success': false,
          'message': message,
          'data': const <Map<String, dynamic>>[],
          'meta': const {
            'hasNext': false,
            'last': true,
            'page': 0,
            'totalPages': 0,
          },
          'timestamp': 0,
        };
      }
    });
  }

  /// [dataContext] contract for request-bound list/grid renderers:
  /// - `requests.{requestKey}` — payload (`success`, `message`, `data`, …)
  /// - `loadingRequestKeys` — `Map<String, bool>` initial load per key
  /// - `initialRequestKeys` — keys auto-dispatched on page load (no `qField`)
  /// - `loadingMoreRequests` — load-more in progress (scaffold footer)
  Map<String, dynamic> _buildRenderContext({
    List<EngineMappedRequest> mappedRequests = const [],
  }) {
    final merged = <String, dynamic>{..._dataContext};
    if (widget.routeParams.isNotEmpty) {
      merged['routeParams'] = Map<String, String>.from(widget.routeParams);
    }
    if (widget.queryParams.isNotEmpty) {
      merged['query'] = Map<String, String>.from(widget.queryParams);
    }
    final config = widget.mobileAppConfig;
    if (config != null) {
      merged['app'] = <String, dynamic>{
        'apiBaseUrl': config.apiBaseUrl,
        'tenantId': config.tenantId,
        'tenantSlug': config.tenantSlug,
        'bundleId': config.bundleId,
        if (config.supportWhatsApp != null)
          'supportWhatsApp': config.supportWhatsApp,
        if (config.supportPhone != null) 'supportPhone': config.supportPhone,
      };
      merged[EngineTheme.contextKey] = EngineTheme.fromConfig(config.theme);
    }
    merged['loadingRequestKeys'] = {
      for (final key in _loadingRequestKeys) key: true,
    };
    merged['initialRequestKeys'] = {
      for (final request in mappedRequests)
        if (request.qField == null) request.key: true,
    };
    if (_requestResults.isNotEmpty) {
      merged['requests'] = _requestResults;
    }
    if (_loadingMoreRequestKeys.isNotEmpty) {
      merged['loadingMoreRequests'] = {
        for (final key in _loadingMoreRequestKeys) key: true,
      };
    }

    final productResult = _requestResults['product-list'];
    if (productResult is Map<String, dynamic>) {
      merged['products'] = productResult['data'] ?? const <dynamic>[];
    }

    if (getIt.isRegistered<CartCubit>()) {
      applyCartToRenderContext(merged, getIt<CartCubit>().state);
    }
    if (getIt.isRegistered<CheckoutCubit>()) {
      applyCheckoutToRenderContext(merged, getIt<CheckoutCubit>().state);
    }
    applyOrderToRenderContext(merged);
    return merged;
  }
}

String orderStatusLabel(OrderStatus status) {
  return switch (status) {
    OrderStatus.pending => 'قيد الانتظار',
    OrderStatus.confirmed => 'مؤكد',
    OrderStatus.processing => 'قيد المعالجة',
    OrderStatus.shipped => 'تم الشحن',
    OrderStatus.delivered => 'تم التسليم',
    OrderStatus.completed => 'مكتمل',
    OrderStatus.cancelled => 'ملغي',
    OrderStatus.returned => 'مرتجع',
    OrderStatus.refunded => 'مسترد',
    OrderStatus.failed => 'فشل',
    OrderStatus.unknown => 'غير معروف',
  };
}

Map<String, dynamic> _enrichOrderJson(CustomerOrder order) {
  final json = Map<String, dynamic>.from(order.toJson());
  json['totalFormatted'] = formatSyp(order.total);
  json['subtotalFormatted'] = formatSyp(order.subtotal);
  json['shippingCostFormatted'] = formatSyp(order.shippingCost);
  json['discountAmountFormatted'] = formatSyp(order.discountAmount);
  json['taxAmountFormatted'] = formatSyp(order.taxAmount);
  json['orderStatusLabel'] = orderStatusLabel(order.orderStatus);
  return json;
}

void applyOrderToRenderContext(Map<String, dynamic> merged) {
  if (!getIt.isRegistered<OrderCubit>()) {
    return;
  }
  final cubit = getIt<OrderCubit>();
  merged['order'] = <String, dynamic>{
    if (cubit.guestLookupError != null) 'guestLookupError': cubit.guestLookupError,
    if (cubit.lastLookupOrderId != null)
      'lastLookupOrderId': cubit.lastLookupOrderId,
  };
}

void applyCartToRenderContext(
  Map<String, dynamic> merged,
  CartState state,
) {
  final cart = switch (state) {
    CartLoaded(:final cart) => cart,
    CartActionSuccess(:final cart) => cart,
    CartFailureState(:final cart) => cart,
    _ => null,
  };

  if (cart == null) {
    merged['cart'] = <String, dynamic>{
      'items': const <Map<String, dynamic>>[],
      'itemCount': 0,
      'subtotalSyp': 0,
      'subtotalFormatted': formatSyp(0),
      'isEmpty': true,
    };
    return;
  }

  merged['cart'] = <String, dynamic>{
    'items': cart.items
        .map((line) {
          final json = Map<String, dynamic>.from(line.toJson());
          json['unitPriceFormatted'] = formatSyp(line.unitPrice);
          json['lineTotalFormatted'] = formatSyp(line.lineTotal);
          return json;
        })
        .toList(),
    'itemCount': cart.itemCount,
    'subtotalSyp': cart.subtotalSyp,
    'subtotalFormatted': formatSyp(cart.subtotalSyp),
    'isEmpty': cart.isEmpty,
  };
}

void applyCheckoutToRenderContext(
  Map<String, dynamic> merged,
  CheckoutState state,
) {
  final draft = switch (state) {
    CheckoutLoaded(:final draft) => draft,
    CheckoutLoading(:final draft) => draft,
    CheckoutFailureState(:final draft) => draft,
    CheckoutActionSuccess(:final draft) => draft,
    _ => null,
  };

  if (draft == null) {
    merged['checkout'] = <String, dynamic>{
      'hasLocation': false,
      'shippingCostSyp': 0,
      'shippingCostFormatted': formatSyp(0),
      'discountMessage': null,
    };
    return;
  }

  final quote = draft.shippingQuote;
  final lastOrder = draft.lastOrder;
  final lastOrderJson = lastOrder == null
      ? null
      : {
          ...lastOrder.toJson(),
          'totalFormatted': formatSyp(lastOrder.total),
        };

  merged['checkout'] = <String, dynamic>{
    'draft': draft.toJson(),
    'hasLocation': draft.hasLocation,
    'shippingCostSyp': quote?.shippingCostSyp ?? 0,
    'shippingCostFormatted': formatSyp(quote?.shippingCostSyp ?? 0),
    'selectedPaymentMethod': draft.paymentMethod,
    'discountMessage': draft.discountMessage,
    if (lastOrderJson != null) 'lastOrder': lastOrderJson,
  };
}

class _CartHost extends StatelessWidget {
  const _CartHost({
    required this.baseRenderContext,
    required this.childBuilder,
  });

  final Map<String, dynamic> baseRenderContext;
  final Widget Function(Map<String, dynamic> ctx) childBuilder;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CartCubit, CartState>(
      listenWhen: (previous, current) =>
          current is CartFailureState || current is CartActionSuccess,
      listener: (context, state) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) {
            return;
          }
          final ctx = Map<String, dynamic>.from(baseRenderContext);
          applyCartToRenderContext(ctx, state);
          if (state is CartFailureState) {
            AppMessenger.showError(
              context,
              state.message,
              dataContext: ctx,
            );
          } else if (state is CartActionSuccess) {
            final message = state.message?.trim();
            if (message != null && message.isNotEmpty) {
              AppMessenger.showSuccess(
                context,
                message,
                dataContext: ctx,
              );
            }
          }
        });
      },
      buildWhen: (previous, current) =>
          current is CartLoaded ||
          current is CartActionSuccess ||
          current is CartFailureState ||
          current is CartLoading,
      builder: (context, state) {
        final ctx = Map<String, dynamic>.from(baseRenderContext);
        applyCartToRenderContext(ctx, state);
        return childBuilder(ctx);
      },
    );
  }
}

class _CheckoutHost extends StatelessWidget {
  const _CheckoutHost({
    required this.baseRenderContext,
    required this.childBuilder,
  });

  final Map<String, dynamic> baseRenderContext;
  final Widget Function(Map<String, dynamic> ctx) childBuilder;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CheckoutCubit, CheckoutState>(
      listenWhen: (previous, current) => current is CheckoutFailureState,
      listener: (context, state) {
        // Hard failures are surfaced by [_CheckoutRequestHost] via AppMessenger.
      },
      buildWhen: (previous, current) =>
          current is CheckoutLoaded ||
          current is CheckoutLoading ||
          current is CheckoutFailureState ||
          current is CheckoutActionSuccess ||
          current is CheckoutInitial,
      builder: (context, state) {
        final ctx = Map<String, dynamic>.from(baseRenderContext);
        applyCheckoutToRenderContext(ctx, state);
        if (getIt.isRegistered<CartCubit>()) {
          applyCartToRenderContext(ctx, context.read<CartCubit>().state);
        }
        return childBuilder(ctx);
      },
    );
  }
}

class _CheckoutRequestHost extends StatelessWidget {
  const _CheckoutRequestHost({
    required this.child,
    required this.renderContext,
  });

  final Widget child;
  final Map<String, dynamic> renderContext;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: BlocListener<CheckoutCubit, CheckoutState>(
        listenWhen: (previous, current) =>
            current is CheckoutFailureState &&
            current.paymentMethodsRequestKey == null,
        listener: (context, state) {
          if (state is! CheckoutFailureState) {
            return;
          }
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!context.mounted) {
              return;
            }
            AppMessenger.showError(
              context,
              state.message,
              dataContext: renderContext,
            );
          });
        },
        child: BlocBuilder<CheckoutCubit, CheckoutState>(
          builder: (context, state) {
            final isLoading = state is CheckoutLoading &&
                (state.operation == 'saveAddress' ||
                    state.operation == 'placeOrder');
            return Stack(
              children: [
                child,
                if (isLoading)
                  const Positioned.fill(
                    child: ColoredBox(
                      color: Color(0x33FFFFFF),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _OrderHost extends StatelessWidget {
  const _OrderHost({
    required this.baseRenderContext,
    required this.childBuilder,
  });

  final Map<String, dynamic> baseRenderContext;
  final Widget Function(Map<String, dynamic> ctx) childBuilder;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<OrderCubit, OrderState>(
      listenWhen: (previous, current) => current is OrderGuestLookupUpdated,
      listener: (context, state) {},
      buildWhen: (previous, current) =>
          current is OrderGuestLookupUpdated ||
          current is OrderInitial ||
          current is OrderLoading ||
          current is OrderActionSuccess,
      builder: (context, state) {
        final ctx = Map<String, dynamic>.from(baseRenderContext);
        applyOrderToRenderContext(ctx);
        return childBuilder(ctx);
      },
    );
  }
}

class _OrderRequestHost extends StatelessWidget {
  const _OrderRequestHost({
    required this.child,
    required this.renderContext,
  });

  final Widget child;
  final Map<String, dynamic> renderContext;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: BlocListener<OrderCubit, OrderState>(
        listenWhen: (previous, current) =>
            current is OrderFailureState && !current.suppressMessenger,
        listener: (context, state) {
          if (state is! OrderFailureState) {
            return;
          }
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!context.mounted) {
              return;
            }
            AppMessenger.showError(
              context,
              state.message,
              dataContext: renderContext,
            );
          });
        },
        child: BlocBuilder<OrderCubit, OrderState>(
          builder: (context, state) {
            final isLoading = state is OrderLoading &&
                (state.operation == 'cancelOrder' ||
                    state.operation == 'loadOrderDetail' ||
                    state.operation == 'openInvoice' ||
                    state.operation == 'lookupGuest');
            return Stack(
              children: [
                child,
                if (isLoading)
                  const Positioned.fill(
                    child: ColoredBox(
                      color: Color(0x33FFFFFF),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _AuthRequestHost extends StatelessWidget {
  const _AuthRequestHost({required this.child, required this.renderContext});

  final Widget child;
  final Map<String, dynamic> renderContext;

  @override
  Widget build(BuildContext context) {
    // Auth routes are shell-excluded and the JSON scaffold renderer does not
    // create a Material Scaffold; we need one here for the loading overlay.
    // User messages use root [AppMessenger], not SnackBar.
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: BlocListener<AuthCubit, AuthState>(
        listenWhen: (previous, current) =>
            current is AuthFailureState ||
            current is AuthOtpRequested ||
            current is AuthAuthenticated,
        listener: (context, state) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!context.mounted) {
              return;
            }

            if (state is AuthAuthenticated) {
              final name = state.tokenResponse.username?.trim();
              final welcome = (name != null && name.isNotEmpty)
                  ? 'تم تسجيل الدخول بنجاح، مرحباً $name'
                  : 'تم تسجيل الدخول بنجاح';
              AppMessenger.showSuccess(
                context,
                welcome,
                dataContext: renderContext,
              );
            }

            if (state is AuthFailureState) {
              var message = state.errMessage;
              if (state is AuthRateLimited && state.retryAfterSeconds != null) {
                message = '$message (${state.retryAfterSeconds}s)';
              }
              AppMessenger.showError(
                context,
                message,
                dataContext: renderContext,
              );
            } else if (state is AuthOtpRequested) {
              AppMessenger.showInfo(
                context,
                state.message,
                dataContext: renderContext,
              );
            }
          });
        },
        child: BlocBuilder<AuthCubit, AuthState>(
          builder: (context, state) {
            final isLoading =
                state is AuthRequestingOtp || state is AuthVerifyingOtp;
            return Stack(
              children: [
                child,
                if (isLoading)
                  const Positioned.fill(
                    child: ColoredBox(
                      color: Color(0x33FFFFFF),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ProductRequestHost extends StatefulWidget {
  const _ProductRequestHost({
    required this.config,
    this.mobileAppConfig,
    this.routeParams = const {},
    this.queryParams = const {},
    required this.mappedRequests,
    required this.pageRequestKeys,
    required this.renderContext,
    required this.formStateStore,
    required this.onPreparePageRequests,
    required this.onRequestLoadingChanged,
    required this.onProductSuccess,
    required this.onProductFailure,
    required this.onSearchSuccess,
    required this.onSearchFailure,
    required this.onAutocompleteSuccess,
    required this.onAutocompleteFailure,
    required this.onProductDetailSuccess,
    required this.onProductDetailFailure,
    required this.onCategoryTreeSuccess,
    required this.onCategorySuccess,
    required this.onCategoryFailure,
    required this.onCheckoutPaymentMethodsSuccess,
    required this.onCheckoutPaymentMethodsFailure,
    required this.onOrdersListSuccess,
    required this.onOrdersListFailure,
    required this.onOrderDetailSuccess,
    required this.onOrderDetailFailure,
    required this.onShipmentTrackSuccess,
    required this.onShipmentTrackEmpty,
  });

  final dynamic config;
  final MobileAppConfig? mobileAppConfig;
  final Map<String, String> routeParams;
  final Map<String, String> queryParams;
  final List<EngineMappedRequest> mappedRequests;
  final Set<String> pageRequestKeys;
  final Map<String, dynamic> renderContext;
  final FormStateStore formStateStore;
  final VoidCallback onPreparePageRequests;
  final void Function(String requestKey, bool isLoading)
  onRequestLoadingChanged;
  final void Function(
    String requestKey,
    dynamic productListResponse,
    bool isLoadMore,
  )
  onProductSuccess;
  final void Function(String requestKey, String message, bool isLoadMore)
  onProductFailure;
  final void Function(
    String requestKey,
    ProductSearchResult searchResult,
    bool isLoadMore,
  )
  onSearchSuccess;
  final void Function(String requestKey, String message, bool isLoadMore)
  onSearchFailure;
  final void Function(
    String requestKey,
    ProductAutocompleteResult autocompleteResult,
  )
  onAutocompleteSuccess;
  final void Function(String requestKey, String message) onAutocompleteFailure;
  final void Function(String requestKey, ProductDetail detail)
  onProductDetailSuccess;
  final void Function(String requestKey, String message) onProductDetailFailure;
  final void Function(String requestKey, List<Category> categories)
  onCategoryTreeSuccess;
  final void Function(String requestKey, Category category) onCategorySuccess;
  final void Function(String requestKey, String message) onCategoryFailure;
  final void Function(String requestKey, List<PublicPaymentMethod> methods)
  onCheckoutPaymentMethodsSuccess;
  final void Function(String requestKey, String message)
  onCheckoutPaymentMethodsFailure;
  final void Function(String requestKey, OrderListResponse response)
  onOrdersListSuccess;
  final void Function(String requestKey, String message) onOrdersListFailure;
  final void Function(String requestKey, CustomerOrder order)
  onOrderDetailSuccess;
  final void Function(String requestKey, String message) onOrderDetailFailure;
  final void Function(String requestKey, CustomerShipmentStatus shipment)
  onShipmentTrackSuccess;
  final void Function(String requestKey, String message) onShipmentTrackEmpty;

  @override
  State<_ProductRequestHost> createState() => _ProductRequestHostState();
}

class _ProductRequestHostState extends State<_ProductRequestHost> {
  static const double _prefetchExtentAfter = 240.0;

  final Set<String> _dispatchedRequestKeys = <String>{};
  final Set<String> _loadingMoreRequestKeys = <String>{};
  final Set<String> _pendingLoadMoreKeys = <String>{};
  final Set<String> _keysSeenLoadingThisSession = <String>{};
  final Map<String, VoidCallback> _queryListenerRemovers = {};
  bool _dispatchScheduled = false;
  bool _isDispatching = false;
  late String _routeSignature;
  Timer? _queryDebounce;

  void _syncLoadingMoreToContext() {
    widget.renderContext['loadingMoreRequests'] = {
      for (final key in _loadingMoreRequestKeys) key: true,
    };
  }

  void _setRequestLoading(String requestKey, bool isLoading) {
    widget.onRequestLoadingChanged(requestKey, isLoading);
  }

  bool _isPageRequestKey(String? requestKey) {
    return requestKey != null && widget.pageRequestKeys.contains(requestKey);
  }

  bool _shouldHandleTerminalProductState(String requestKey) {
    return _dispatchedRequestKeys.contains(requestKey) &&
        _keysSeenLoadingThisSession.contains(requestKey);
  }

  static String? _requestKeyFromProductState(ProductState state) {
    return switch (state) {
      ProductLoading(:final requestKey) => requestKey,
      ProductSuccess(:final requestKey) => requestKey,
      ProductFailure(:final requestKey) => requestKey,
      _ => null,
    };
  }

  static String? _requestKeyFromSearchState(ProductSearchState state) {
    return switch (state) {
      ProductSearchLoading(:final requestKey) => requestKey,
      ProductSearchSuccess(:final requestKey) => requestKey,
      ProductSearchFailure(:final requestKey) => requestKey,
      _ => null,
    };
  }

  static String? _requestKeyFromAutocompleteState(
    ProductAutocompleteState state,
  ) {
    return switch (state) {
      ProductAutocompleteLoading(:final requestKey) => requestKey,
      ProductAutocompleteSuccess(:final requestKey) => requestKey,
      ProductAutocompleteFailure(:final requestKey) => requestKey,
      _ => null,
    };
  }

  static String? _requestKeyFromDetailState(ProductDetailState state) {
    return switch (state) {
      ProductDetailLoading(:final requestKey) => requestKey,
      ProductDetailSuccess(:final requestKey) => requestKey,
      ProductDetailFailure(:final requestKey) => requestKey,
      _ => null,
    };
  }

  static String? _requestKeyFromCategoryState(CategoryState state) {
    return switch (state) {
      CategoryLoading(:final requestKey) => requestKey,
      CategoryTreeSuccess(:final requestKey) => requestKey,
      CategorySuccess(:final requestKey) => requestKey,
      CategoryFailure(:final requestKey) => requestKey,
      _ => null,
    };
  }

  bool _shouldHandleTerminalCategoryState(String requestKey) {
    return _dispatchedRequestKeys.contains(requestKey) &&
        _keysSeenLoadingThisSession.contains(requestKey);
  }

  static String? _requestKeyFromCheckoutState(CheckoutState state) {
    return switch (state) {
      CheckoutLoading(:final paymentMethodsRequestKey) =>
        paymentMethodsRequestKey,
      CheckoutLoaded(:final paymentMethodsRequestKey) =>
        paymentMethodsRequestKey,
      CheckoutFailureState(:final paymentMethodsRequestKey) =>
        paymentMethodsRequestKey,
      _ => null,
    };
  }

  bool _shouldHandleTerminalCheckoutState(String requestKey) {
    return _dispatchedRequestKeys.contains(requestKey) &&
        _keysSeenLoadingThisSession.contains(requestKey);
  }

  static String? _requestKeyFromOrderState(OrderState state) {
    return switch (state) {
      OrderLoading(:final requestKey) => requestKey,
      OrderListSuccess(:final requestKey) => requestKey,
      OrderDetailSuccess(:final requestKey) => requestKey,
      OrderShipmentSuccess(:final requestKey) => requestKey,
      OrderShipmentEmpty(:final requestKey) => requestKey,
      OrderFailureState(:final requestKey) => requestKey,
      _ => null,
    };
  }

  bool _shouldHandleTerminalOrderState(String requestKey) {
    return _dispatchedRequestKeys.contains(requestKey) &&
        _keysSeenLoadingThisSession.contains(requestKey);
  }

  @override
  void initState() {
    super.initState();
    _routeSignature = _buildRouteSignature(widget.routeParams);
    _keysSeenLoadingThisSession.clear();
    _bindFormQueryListeners();
    _scheduleDispatch();
    _scheduleLoadMoreCheck();
  }

  @override
  void dispose() {
    _queryDebounce?.cancel();
    for (final remove in _queryListenerRemovers.values) {
      remove();
    }
    _queryListenerRemovers.clear();
    super.dispose();
  }

  void _bindFormQueryListeners() {
    for (final request in widget.mappedRequests) {
      final fieldId = request.qField;
      if (fieldId == null || fieldId.isEmpty) {
        continue;
      }

      final controller = widget.formStateStore.controllerFor(fieldId);
      void onChanged() => _onFormQueryChanged(request);
      controller.addListener(onChanged);
      _queryListenerRemovers[request.key] = () {
        controller.removeListener(onChanged);
      };
    }
  }

  void _onFormQueryChanged(EngineMappedRequest request) {
    _queryDebounce?.cancel();
    _queryDebounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) {
        return;
      }
      unawaited(_dispatchQueryRequest(request));
    });
  }

  String? _formValueFor(String fieldId) {
    final stored = widget.formStateStore.valueFor(fieldId);
    if (stored != null && stored.isNotEmpty) {
      return stored;
    }
    final text = widget.formStateStore.controllerFor(fieldId).text.trim();
    return text.isEmpty ? null : text;
  }

  @override
  void didUpdateWidget(covariant _ProductRequestHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextRouteSignature = _buildRouteSignature(widget.routeParams);
    final routeParamsChanged = nextRouteSignature != _routeSignature;
    if (routeParamsChanged) {
      _routeSignature = nextRouteSignature;
    }

    if (oldWidget.config != widget.config || routeParamsChanged) {
      _dispatchedRequestKeys.clear();
      _keysSeenLoadingThisSession.clear();
      _dispatchScheduled = false;
      widget.onPreparePageRequests();
      _scheduleDispatch();
      _scheduleLoadMoreCheck();
    }
  }

  void _scheduleLoadMoreCheck() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final metrics = _lastScrollMetrics;
      if (metrics != null) {
        _maybeLoadMore(metrics);
      }
    });
  }

  ScrollMetrics? _lastScrollMetrics;

  bool _onScrollNotification(ScrollNotification notification) {
    if (notification is ScrollUpdateNotification ||
        notification is ScrollEndNotification ||
        notification is ScrollMetricsNotification) {
      _lastScrollMetrics = notification.metrics;
      _maybeLoadMore(notification.metrics);
    }
    return false;
  }

  void _maybeLoadMore(ScrollMetrics metrics) {
    final shouldPrefetch =
        metrics.extentAfter <= _prefetchExtentAfter ||
        metrics.maxScrollExtent == 0.0;
    if (!shouldPrefetch) {
      return;
    }
    _tryLoadMoreForEligibleRequests();
  }

  void _tryLoadMoreForEligibleRequests() {
    if (!EngineRequestMapper.needsProductCubit(widget.mappedRequests)) {
      return;
    }

    final requestsByKey = widget.renderContext['requests'];
    final loadingMoreByKey = widget.renderContext['loadingMoreRequests'];
    if (requestsByKey is! Map<String, dynamic>) {
      return;
    }

    for (final request in widget.mappedRequests) {
      if (!EngineRequestMapper.supportsProductListLoadMore(request)) {
        continue;
      }

      final rawResponse = requestsByKey[request.key];
      if (rawResponse is! Map<String, dynamic>) {
        continue;
      }
      if (rawResponse['success'] == false) {
        continue;
      }

      final response = ProductListResponse.fromJson(rawResponse);
      if (_pendingLoadMoreKeys.contains(request.key) &&
          (loadingMoreByKey is! Map<String, dynamic> ||
              loadingMoreByKey[request.key] != true)) {
        _pendingLoadMoreKeys.remove(request.key);
      }

      if (!response.meta.hasNext || response.meta.last) {
        continue;
      }
      if (loadingMoreByKey is Map<String, dynamic> &&
          loadingMoreByKey[request.key] == true) {
        continue;
      }
      if (_pendingLoadMoreKeys.contains(request.key)) {
        continue;
      }

      _pendingLoadMoreKeys.add(request.key);
      context.read<ProductCubit>().loadNextPage(
        response,
        requestKey: request.key,
      );
    }
  }

  static String _buildRouteSignature(Map<String, String> routeParams) {
    if (routeParams.isEmpty) {
      return '';
    }
    final keys = routeParams.keys.toList()..sort();
    return keys.map((key) => '$key=${routeParams[key]}').join('|');
  }

  void _scheduleDispatch() {
    if (_dispatchScheduled) {
      return;
    }
    _dispatchScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _dispatchRequests();
    });
  }

  Future<void> _dispatchQueryRequest(EngineMappedRequest request) async {
    await _dispatchRequests(requests: [request]);
  }

  Future<void> _dispatchRequests({List<EngineMappedRequest>? requests}) async {
    final isInitialLoad = requests == null;
    if (isInitialLoad && _isDispatching) {
      return;
    }

    final mapped = requests ?? widget.mappedRequests;
    final pending = mapped
        .where(
          (request) =>
              request.qField == null &&
              !_dispatchedRequestKeys.contains(request.key),
        )
        .toList(growable: false);

    if (pending.isEmpty && isInitialLoad) {
      _dispatchScheduled = false;
      return;
    }

    final toDispatch = requests ?? pending;
    if (toDispatch.isEmpty) {
      _dispatchScheduled = false;
      return;
    }

    if (isInitialLoad) {
      _dispatchedRequestKeys.addAll(toDispatch.map((request) => request.key));
      _isDispatching = true;
    }

    ProductCubit? productCubit;
    ProductSearchCubit? productSearchCubit;
    ProductAutocompleteCubit? productAutocompleteCubit;
    ProductDetailCubit? productDetailCubit;
    CategoryCubit? categoryCubit;
    CheckoutCubit? checkoutCubit;
    OrderCubit? orderCubit;

    if (EngineRequestMapper.needsProductCubit(widget.mappedRequests)) {
      productCubit = context.read<ProductCubit>();
    }
    if (EngineRequestMapper.needsSearchCubit(widget.mappedRequests)) {
      productSearchCubit = context.read<ProductSearchCubit>();
    }
    if (EngineRequestMapper.needsAutocompleteCubit(widget.mappedRequests)) {
      productAutocompleteCubit = context.read<ProductAutocompleteCubit>();
    }
    if (EngineRequestMapper.needsProductDetailCubit(widget.mappedRequests)) {
      productDetailCubit = context.read<ProductDetailCubit>();
    }
    if (EngineRequestMapper.needsCategoryCubit(widget.mappedRequests)) {
      categoryCubit = context.read<CategoryCubit>();
    }
    if (EngineRequestMapper.needsCheckoutCubit(widget.mappedRequests)) {
      checkoutCubit = context.read<CheckoutCubit>();
    }
    if (EngineRequestMapper.needsOrderCubit(widget.mappedRequests)) {
      orderCubit = context.read<OrderCubit>();
    }

    try {
      await EngineRequestMapper.dispatchRequests(
        productCubit: productCubit,
        productSearchCubit: productSearchCubit,
        productAutocompleteCubit: productAutocompleteCubit,
        productDetailCubit: productDetailCubit,
        categoryCubit: categoryCubit,
        checkoutCubit: checkoutCubit,
        orderCubit: orderCubit,
        tenantId: _resolveTenantIdForRequests(),
        requests: toDispatch,
        formValueFor: _formValueFor,
      );
    } finally {
      if (isInitialLoad) {
        _isDispatching = false;
        _dispatchScheduled = false;
      }
    }
  }

  String? _resolveTenantIdForRequests() {
    final sessionTenantId = getIt<TokenCubit>().tenantId;
    if (getIt.isRegistered<NetworkConfig>()) {
      return getIt<NetworkConfig>().effectiveTenantId(
        sessionTenantId: sessionTenantId,
      );
    }

    final appConfig = widget.mobileAppConfig;
    return TenantResolver.resolve(
      configTenantId: appConfig?.tenantId,
      configTenantSlug: appConfig?.tenantSlug,
      sessionTenantId: sessionTenantId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final listeners = <BlocListener<dynamic, dynamic>>[];

    if (EngineRequestMapper.needsProductCubit(widget.mappedRequests)) {
      listeners.add(
        BlocListener<ProductCubit, ProductState>(
          listenWhen: (previous, current) =>
              _isPageRequestKey(_requestKeyFromProductState(current)),
          listener: (context, state) {
            if (state is ProductLoading) {
              _keysSeenLoadingThisSession.add(state.requestKey);
              if (state.isLoadMore) {
                setState(() {
                  _loadingMoreRequestKeys.add(state.requestKey);
                  _syncLoadingMoreToContext();
                });
              } else {
                _setRequestLoading(state.requestKey, true);
              }
            } else if (state is ProductSuccess) {
              if (!_shouldHandleTerminalProductState(state.requestKey)) {
                return;
              }
              if (state.isLoadMore) {
                setState(() {
                  _loadingMoreRequestKeys.remove(state.requestKey);
                  _syncLoadingMoreToContext();
                });
              } else {
                _setRequestLoading(state.requestKey, false);
              }
              widget.onProductSuccess(
                state.requestKey,
                state.productListResponse,
                state.isLoadMore,
              );
              _scheduleLoadMoreCheck();
            } else if (state is ProductFailure) {
              if (!_shouldHandleTerminalProductState(state.requestKey)) {
                return;
              }
              if (state.isLoadMore) {
                setState(() {
                  _loadingMoreRequestKeys.remove(state.requestKey);
                  _syncLoadingMoreToContext();
                });
              } else {
                _setRequestLoading(state.requestKey, false);
              }
              widget.onProductFailure(
                state.requestKey,
                state.errMessage,
                state.isLoadMore,
              );
            }
          },
        ),
      );
    }

    if (EngineRequestMapper.needsSearchCubit(widget.mappedRequests)) {
      listeners.add(
        BlocListener<ProductSearchCubit, ProductSearchState>(
          listenWhen: (previous, current) =>
              _isPageRequestKey(_requestKeyFromSearchState(current)),
          listener: (context, state) {
            if (state is ProductSearchLoading) {
              _keysSeenLoadingThisSession.add(state.requestKey);
              if (state.isLoadMore) {
                setState(() {
                  _loadingMoreRequestKeys.add(state.requestKey);
                  _syncLoadingMoreToContext();
                });
              } else {
                _setRequestLoading(state.requestKey, true);
              }
            } else if (state is ProductSearchSuccess) {
              if (!_shouldHandleTerminalProductState(state.requestKey)) {
                return;
              }
              if (state.isLoadMore) {
                setState(() {
                  _loadingMoreRequestKeys.remove(state.requestKey);
                  _syncLoadingMoreToContext();
                });
              } else {
                _setRequestLoading(state.requestKey, false);
              }
              widget.onSearchSuccess(
                state.requestKey,
                state.searchResult,
                state.isLoadMore,
              );
            } else if (state is ProductSearchFailure) {
              if (!_shouldHandleTerminalProductState(state.requestKey)) {
                return;
              }
              if (state.isLoadMore) {
                setState(() {
                  _loadingMoreRequestKeys.remove(state.requestKey);
                  _syncLoadingMoreToContext();
                });
              } else {
                _setRequestLoading(state.requestKey, false);
              }
              widget.onSearchFailure(
                state.requestKey,
                state.errMessage,
                state.isLoadMore,
              );
            }
          },
        ),
      );
    }

    if (EngineRequestMapper.needsAutocompleteCubit(widget.mappedRequests)) {
      listeners.add(
        BlocListener<ProductAutocompleteCubit, ProductAutocompleteState>(
          listenWhen: (previous, current) =>
              _isPageRequestKey(_requestKeyFromAutocompleteState(current)),
          listener: (context, state) {
            if (state is ProductAutocompleteLoading) {
              _keysSeenLoadingThisSession.add(state.requestKey);
              _setRequestLoading(state.requestKey, true);
            } else if (state is ProductAutocompleteSuccess) {
              if (!_shouldHandleTerminalProductState(state.requestKey)) {
                return;
              }
              _setRequestLoading(state.requestKey, false);
              widget.onAutocompleteSuccess(
                state.requestKey,
                state.autocompleteResult,
              );
            } else if (state is ProductAutocompleteFailure) {
              if (!_shouldHandleTerminalProductState(state.requestKey)) {
                return;
              }
              _setRequestLoading(state.requestKey, false);
              widget.onAutocompleteFailure(state.requestKey, state.errMessage);
            }
          },
        ),
      );
    }

    if (EngineRequestMapper.needsProductDetailCubit(widget.mappedRequests)) {
      listeners.add(
        BlocListener<ProductDetailCubit, ProductDetailState>(
          listenWhen: (previous, current) =>
              _isPageRequestKey(_requestKeyFromDetailState(current)),
          listener: (context, state) {
            if (state is ProductDetailLoading) {
              _keysSeenLoadingThisSession.add(state.requestKey);
              _setRequestLoading(state.requestKey, true);
            } else if (state is ProductDetailSuccess) {
              if (!_shouldHandleTerminalProductState(state.requestKey)) {
                return;
              }
              _setRequestLoading(state.requestKey, false);
              widget.onProductDetailSuccess(state.requestKey, state.detail);
            } else if (state is ProductDetailFailure) {
              if (!_shouldHandleTerminalProductState(state.requestKey)) {
                return;
              }
              _setRequestLoading(state.requestKey, false);
              widget.onProductDetailFailure(state.requestKey, state.errMessage);
            }
          },
        ),
      );
    }

    if (EngineRequestMapper.needsCategoryCubit(widget.mappedRequests)) {
      listeners.add(
        BlocListener<CategoryCubit, CategoryState>(
          listenWhen: (previous, current) =>
              _isPageRequestKey(_requestKeyFromCategoryState(current)),
          listener: (context, state) {
            if (state is CategoryLoading) {
              _keysSeenLoadingThisSession.add(state.requestKey);
              _setRequestLoading(state.requestKey, true);
            } else if (state is CategoryTreeSuccess) {
              if (!_shouldHandleTerminalCategoryState(state.requestKey)) {
                return;
              }
              _setRequestLoading(state.requestKey, false);
              widget.onCategoryTreeSuccess(state.requestKey, state.categories);
            } else if (state is CategorySuccess) {
              if (!_shouldHandleTerminalCategoryState(state.requestKey)) {
                return;
              }
              _setRequestLoading(state.requestKey, false);
              widget.onCategorySuccess(state.requestKey, state.category);
            } else if (state is CategoryFailure) {
              if (!_shouldHandleTerminalCategoryState(state.requestKey)) {
                return;
              }
              _setRequestLoading(state.requestKey, false);
              widget.onCategoryFailure(state.requestKey, state.errMessage);
            }
          },
        ),
      );
    }

    if (EngineRequestMapper.needsCheckoutCubit(widget.mappedRequests)) {
      listeners.add(
        BlocListener<CheckoutCubit, CheckoutState>(
          listenWhen: (previous, current) {
            final key = _requestKeyFromCheckoutState(current);
            return key != null && _isPageRequestKey(key);
          },
          listener: (context, state) {
            final requestKey = _requestKeyFromCheckoutState(state);
            if (requestKey == null) {
              return;
            }

            if (state is CheckoutLoading &&
                state.operation == 'loadPaymentMethods') {
              _keysSeenLoadingThisSession.add(requestKey);
              _setRequestLoading(requestKey, true);
            } else if (state is CheckoutLoaded &&
                state.paymentMethods != null &&
                state.paymentMethodsRequestKey == requestKey) {
              if (!_shouldHandleTerminalCheckoutState(requestKey)) {
                return;
              }
              _setRequestLoading(requestKey, false);
              widget.onCheckoutPaymentMethodsSuccess(
                requestKey,
                state.paymentMethods!,
              );
            } else if (state is CheckoutFailureState) {
              if (!_shouldHandleTerminalCheckoutState(requestKey)) {
                return;
              }
              _setRequestLoading(requestKey, false);
              widget.onCheckoutPaymentMethodsFailure(
                requestKey,
                state.message,
              );
            }
          },
        ),
      );
    }

    if (EngineRequestMapper.needsOrderCubit(widget.mappedRequests)) {
      listeners.add(
        BlocListener<OrderCubit, OrderState>(
          listenWhen: (previous, current) {
            final key = _requestKeyFromOrderState(current);
            return key != null && _isPageRequestKey(key);
          },
          listener: (context, state) {
            final requestKey = _requestKeyFromOrderState(state);
            if (requestKey == null) {
              return;
            }

            if (state is OrderLoading) {
              _keysSeenLoadingThisSession.add(requestKey);
              _setRequestLoading(requestKey, true);
            } else if (state is OrderListSuccess) {
              if (!_shouldHandleTerminalOrderState(requestKey)) {
                return;
              }
              _setRequestLoading(requestKey, false);
              widget.onOrdersListSuccess(requestKey, state.response);
            } else if (state is OrderDetailSuccess) {
              if (!_shouldHandleTerminalOrderState(requestKey)) {
                return;
              }
              _setRequestLoading(requestKey, false);
              widget.onOrderDetailSuccess(requestKey, state.order);
            } else if (state is OrderShipmentSuccess) {
              if (!_shouldHandleTerminalOrderState(requestKey)) {
                return;
              }
              _setRequestLoading(requestKey, false);
              widget.onShipmentTrackSuccess(requestKey, state.shipment);
            } else if (state is OrderShipmentEmpty) {
              if (!_shouldHandleTerminalOrderState(requestKey)) {
                return;
              }
              _setRequestLoading(requestKey, false);
              widget.onShipmentTrackEmpty(requestKey, state.message);
            } else if (state is OrderFailureState) {
              if (!_shouldHandleTerminalOrderState(requestKey)) {
                return;
              }
              _setRequestLoading(requestKey, false);
              if (state.operation == 'loadOrders') {
                widget.onOrdersListFailure(requestKey, state.message);
              } else {
                widget.onOrderDetailFailure(requestKey, state.message);
              }
            }
          },
        ),
      );
    }

    return MultiBlocListener(
      listeners: listeners,
      child: NotificationListener<ScrollNotification>(
        onNotification: _onScrollNotification,
        child: ScreenRenderer.withPrimitives().render(
          widget.config,
          context: context,
          dataContext: widget.renderContext,
        ),
      ),
    );
  }
}

/// Transparent status bar on splash routes (purple stays on in-app UI only).
class _SplashSystemUiOverlay extends StatelessWidget {
  const _SplashSystemUiOverlay({required this.pageRoute, required this.child});

  final String? pageRoute;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: child,
    );
  }
}
