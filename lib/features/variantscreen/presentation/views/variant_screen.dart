import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sooq_merchant/core/cubits/token_cubit/token_cubit.dart';
import 'package:sooq_merchant/core/network/network_config.dart';
import 'package:sooq_merchant/core/network/tenant_resolver.dart';
import 'package:sooq_merchant/core/feedback/app_messenger.dart';
import 'package:sooq_merchant/core/navigation/auth_redirect.dart';

import 'package:sooq_merchant/config/mobile_app_config.dart';
import 'package:sooq_merchant/core/utils/service_locator.dart';
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
  final Set<String> _loadingMoreRequestKeys = <String>{};

  static const _authRoutes = {'/auth/login', '/auth/otp-reset'};

  static const _splashRoutes = {'/splash', '/splash-carousel'};

  bool get _isAuthRoute =>
      widget.pageRoute != null && _authRoutes.contains(widget.pageRoute);

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
    final renderContext = _buildRenderContext();

    Widget content;
    if (mappedRequests.isEmpty) {
      content = ScreenRenderer.withPrimitives().render(
        config,
        context: context,
        dataContext: renderContext,
      );
    } else {
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
          BlocProvider<CategoryCubit>(
            create: (_) => getIt<CategoryCubit>(),
          ),
      ];

      content = MultiBlocProvider(
        providers: providers,
        child: _ProductRequestHost(
          config: config,
          mobileAppConfig: widget.mobileAppConfig,
          routeParams: widget.routeParams,
          queryParams: widget.queryParams,
          mappedRequests: mappedRequests,
          renderContext: renderContext,
          formStateStore: _formStateStore,
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
        ),
      );
    }

    if (_isAuthRoute) {
      return BlocProvider<AuthCubit>.value(
        value: getIt<AuthCubit>(),
        child: _AuthRequestHost(
          renderContext: renderContext,
          child: content,
        ),
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
      if (isLoadMore) {
        _loadingMoreRequestKeys.remove(requestKey);
      }
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
    });
  }

  void _handleProductDetailSuccess(String requestKey, ProductDetail detail) {
    if (!mounted) {
      return;
    }

    setState(() {
      _requestResults[requestKey] = {
        'success': true,
        'data': detail.toJson(),
      };
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
  Map<String, dynamic> _buildRenderContext() {
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
      };
      merged[EngineTheme.contextKey] = EngineTheme.fromConfig(config.theme);
    }
    merged['loadingRequestKeys'] = const <String, bool>{};
    if (_requestResults.isNotEmpty) {
      merged['requests'] = _requestResults;
      merged['loadingMoreRequests'] = {
        for (final key in _loadingMoreRequestKeys) key: true,
      };

      final productResult = _requestResults['product-list'];
      if (productResult is Map<String, dynamic>) {
        merged['products'] = productResult['data'] ?? const <dynamic>[];
      }
    }
    return merged;
  }
}

class _AuthRequestHost extends StatelessWidget {
  const _AuthRequestHost({
    required this.child,
    required this.renderContext,
  });

  final Widget child;
  final Map<String, dynamic> renderContext;

  @override
  Widget build(BuildContext context) {
    // Auth routes are shell-excluded and the JSON scaffold renderer does not
    // create a Material Scaffold; we need one here for the loading overlay.
    // User messages use root [AppMessenger], not SnackBar.
    return Scaffold(
      backgroundColor: Colors.transparent,
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
              context.go(AuthRedirect.homeRoute);
              return;
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
    required this.renderContext,
    required this.formStateStore,
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
  });

  final dynamic config;
  final MobileAppConfig? mobileAppConfig;
  final Map<String, String> routeParams;
  final Map<String, String> queryParams;
  final List<EngineMappedRequest> mappedRequests;
  final Map<String, dynamic> renderContext;
  final FormStateStore formStateStore;
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

  @override
  State<_ProductRequestHost> createState() => _ProductRequestHostState();
}

class _ProductRequestHostState extends State<_ProductRequestHost> {
  static const double _prefetchExtentAfter = 240.0;

  final Set<String> _dispatchedRequestKeys = <String>{};
  final Set<String> _loadingRequestKeys = <String>{};
  final Set<String> _loadingMoreRequestKeys = <String>{};
  final Set<String> _pendingLoadMoreKeys = <String>{};
  final Map<String, VoidCallback> _queryListenerRemovers = {};
  bool _dispatchScheduled = false;
  bool _isDispatching = false;
  late String _routeSignature;
  Timer? _queryDebounce;

  void _syncLoadingFlagsToContext() {
    widget.renderContext['loadingRequestKeys'] = {
      for (final key in _loadingRequestKeys) key: true,
    };
    widget.renderContext['loadingMoreRequests'] = {
      for (final key in _loadingMoreRequestKeys) key: true,
    };
  }

  @override
  void initState() {
    super.initState();
    _routeSignature = _buildRouteSignature(widget.routeParams);
    widget.renderContext['initialRequestKeys'] = {
      for (final request in widget.mappedRequests)
        if (request.qField == null) request.key: true,
    };
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
      _dispatchScheduled = false;
      widget.renderContext['initialRequestKeys'] = {
        for (final request in widget.mappedRequests)
          if (request.qField == null) request.key: true,
      };
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

    try {
      await EngineRequestMapper.dispatchRequests(
        productCubit: productCubit,
        productSearchCubit: productSearchCubit,
        productAutocompleteCubit: productAutocompleteCubit,
        productDetailCubit: productDetailCubit,
        categoryCubit: categoryCubit,
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
          listener: (context, state) {
            if (state is ProductLoading) {
              setState(() {
                if (state.isLoadMore) {
                  _loadingMoreRequestKeys.add(state.requestKey);
                } else {
                  _loadingRequestKeys.add(state.requestKey);
                }
                _syncLoadingFlagsToContext();
              });
            } else if (state is ProductSuccess) {
              setState(() {
                _loadingRequestKeys.remove(state.requestKey);
                _loadingMoreRequestKeys.remove(state.requestKey);
                _syncLoadingFlagsToContext();
              });
              widget.onProductSuccess(
                state.requestKey,
                state.productListResponse,
                state.isLoadMore,
              );
              _scheduleLoadMoreCheck();
            } else if (state is ProductFailure) {
              setState(() {
                _loadingRequestKeys.remove(state.requestKey);
                _loadingMoreRequestKeys.remove(state.requestKey);
                _syncLoadingFlagsToContext();
              });
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
          listener: (context, state) {
            if (state is ProductSearchLoading) {
              setState(() {
                if (state.isLoadMore) {
                  _loadingMoreRequestKeys.add(state.requestKey);
                } else {
                  _loadingRequestKeys.add(state.requestKey);
                }
                _syncLoadingFlagsToContext();
              });
            } else if (state is ProductSearchSuccess) {
              setState(() {
                _loadingRequestKeys.remove(state.requestKey);
                _loadingMoreRequestKeys.remove(state.requestKey);
                _syncLoadingFlagsToContext();
              });
              widget.onSearchSuccess(
                state.requestKey,
                state.searchResult,
                state.isLoadMore,
              );
            } else if (state is ProductSearchFailure) {
              setState(() {
                _loadingRequestKeys.remove(state.requestKey);
                _loadingMoreRequestKeys.remove(state.requestKey);
                _syncLoadingFlagsToContext();
              });
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
          listener: (context, state) {
            if (state is ProductAutocompleteLoading) {
              setState(() {
                _loadingRequestKeys.add(state.requestKey);
                _syncLoadingFlagsToContext();
              });
            } else if (state is ProductAutocompleteSuccess) {
              setState(() {
                _loadingRequestKeys.remove(state.requestKey);
                _syncLoadingFlagsToContext();
              });
              widget.onAutocompleteSuccess(
                state.requestKey,
                state.autocompleteResult,
              );
            } else if (state is ProductAutocompleteFailure) {
              setState(() {
                _loadingRequestKeys.remove(state.requestKey);
                _syncLoadingFlagsToContext();
              });
              widget.onAutocompleteFailure(
                state.requestKey,
                state.errMessage,
              );
            }
          },
        ),
      );
    }

    if (EngineRequestMapper.needsProductDetailCubit(widget.mappedRequests)) {
      listeners.add(
        BlocListener<ProductDetailCubit, ProductDetailState>(
          listener: (context, state) {
            if (state is ProductDetailLoading) {
              setState(() {
                _loadingRequestKeys.add(state.requestKey);
                _syncLoadingFlagsToContext();
              });
            } else if (state is ProductDetailSuccess) {
              setState(() {
                _loadingRequestKeys.remove(state.requestKey);
                _syncLoadingFlagsToContext();
              });
              widget.onProductDetailSuccess(
                state.requestKey,
                state.detail,
              );
            } else if (state is ProductDetailFailure) {
              setState(() {
                _loadingRequestKeys.remove(state.requestKey);
                _syncLoadingFlagsToContext();
              });
              widget.onProductDetailFailure(
                state.requestKey,
                state.errMessage,
              );
            }
          },
        ),
      );
    }

    if (EngineRequestMapper.needsCategoryCubit(widget.mappedRequests)) {
      listeners.add(
        BlocListener<CategoryCubit, CategoryState>(
          listener: (context, state) {
            if (state is CategoryLoading) {
              setState(() {
                _loadingRequestKeys.add(state.requestKey);
                _syncLoadingFlagsToContext();
              });
            } else if (state is CategoryTreeSuccess) {
              setState(() {
                _loadingRequestKeys.remove(state.requestKey);
                _syncLoadingFlagsToContext();
              });
              widget.onCategoryTreeSuccess(
                state.requestKey,
                state.categories,
              );
            } else if (state is CategorySuccess) {
              setState(() {
                _loadingRequestKeys.remove(state.requestKey);
                _syncLoadingFlagsToContext();
              });
              widget.onCategorySuccess(
                state.requestKey,
                state.category,
              );
            } else if (state is CategoryFailure) {
              setState(() {
                _loadingRequestKeys.remove(state.requestKey);
                _syncLoadingFlagsToContext();
              });
              widget.onCategoryFailure(
                state.requestKey,
                state.errMessage,
              );
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
  const _SplashSystemUiOverlay({
    required this.pageRoute,
    required this.child,
  });

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
