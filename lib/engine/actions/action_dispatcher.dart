import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/cubits/token_cubit/token_cubit.dart';
import '../../core/feedback/app_messenger.dart';
import '../../core/navigation/app_navigation.dart';
import '../../core/navigation/auth_prompt_sheet.dart';
import '../../core/navigation/auth_redirect.dart';
import '../../core/network/network_config.dart';
import '../../core/utils/api_service.dart';
import '../../core/utils/app_logger.dart';
import '../../core/utils/syp_formatter.dart';
import '../../core/utils/service_locator.dart';
import '../../features/auth/presentation/manager/auth_cubit/auth_cubit.dart';
import '../../features/commerce/cart/presentation/manager/cart_cubit/cart_cubit.dart';
import '../../features/commerce/cart/presentation/manager/cart_cubit/cart_state.dart';
import '../../features/commerce/checkout/presentation/manager/checkout_cubit/checkout_cubit.dart';
import '../../features/commerce/checkout/presentation/manager/checkout_cubit/checkout_state.dart';
import '../../features/commerce/order/presentation/manager/order_cubit/order_cubit.dart';
import '../../features/commerce/order/presentation/manager/order_cubit/order_state.dart';
import '../../features/commerce/wishlist/presentation/manager/wishlist_cubit/wishlist_cubit.dart';
import '../../features/commerce/wishlist/presentation/manager/wishlist_cubit/wishlist_state.dart';
import '../engine_page_chrome.dart';
import '../form/form_state_store.dart';
import '../page/page_state_store.dart';
import '../tree/parsers/data_context_path.dart';
import 'action_value_resolver.dart';
import 'contact_uri_builder.dart';

class EngineActionDispatcher {
  static const contextKey = '_engineActionDispatcher';

  EngineActionDispatcher({
    required BuildContext context,
    FormStateStore? formState,
    PageStateStore? pageStateStore,
    Map<String, dynamic>? dataContext,
  })  : _context = context,
        _formState = formState,
        _pageStateStore = pageStateStore,
        _dataContext = dataContext;

  final BuildContext _context;
  final FormStateStore? _formState;
  final PageStateStore? _pageStateStore;
  final Map<String, dynamic>? _dataContext;

  VoidCallback? resolveTap(
    Map<String, dynamic>? action, {
    Map<String, dynamic>? dataContext,
  }) {
    if (action == null) return null;
    return () => dispatch(action, dataContext: dataContext);
  }

  Future<void> dispatch(
    Map<String, dynamic> action, {
    String? value,
    String? fieldId,
    Map<String, dynamic>? dataContext,
  }) async {
    final mergedContext = dataContext ?? _dataContext;
    final requireValidForm = action['requireValidForm'] == true;
    if (requireValidForm && _formState != null) {
      final formId = action['formId'] as String? ?? '';
      if (!_formState.validate(formId)) {
        AppMessenger.showError(_context, 'يرجى تصحيح الحقول');
        return;
      }
    }
    if (!_passesAuthGate(action, dataContext: mergedContext)) {
      return;
    }

    final type = action['type'] as String?;
    switch (type) {
      case 'navigate':
        _handleNavigate(action, dataContext: mergedContext);
        return;
      case 'apiCall':
        await _handleApiCall(action, value: value, fieldId: fieldId);
        return;
      case 'cubitCall':
        await _handleCubitCall(action, dataContext: mergedContext);
        return;
      case 'openDrawer':
        _handleDrawer(action, open: true, dataContext: mergedContext);
        return;
      case 'closeDrawer':
        _handleDrawer(action, open: false, dataContext: mergedContext);
        return;
      case 'openUrl':
        await _handleOpenUrl(action, dataContext: mergedContext);
        return;
      case 'openContact':
        await _handleOpenContact(action, dataContext: mergedContext);
        return;
      case 'setPageState':
        await _handleSetPageState(action, dataContext: mergedContext);
        return;
      case 'reloadRequest':
        await _handleReloadRequest(action);
        return;
      default:
        AppLogger.debug('[ActionDispatcher] Unsupported action type: $type');
        return;
    }
  }

  Future<void> _handleSetPageState(
    Map<String, dynamic> action, {
    Map<String, dynamic>? dataContext,
  }) async {
    final store = _pageStateStore ??
        (dataContext?[PageStateStore.contextKey] as PageStateStore?);
    if (store == null) {
      AppLogger.debug('[ActionDispatcher] setPageState: no PageStateStore');
      return;
    }

    final values = action['values'];
    if (values is! Map) {
      AppLogger.debug('[ActionDispatcher] setPageState: missing values map');
      return;
    }

    final patch = <String, dynamic>{};
    for (final entry in values.entries) {
      final resolved = _resolveCubitParams(
        {entry.key: entry.value},
        dataContext: dataContext,
      );
      patch[entry.key] = resolved.containsKey(entry.key)
          ? resolved[entry.key]
          : null;
    }
    store.update(patch);

    final onSuccess = action['onSuccess'];
    if (onSuccess is Map<String, dynamic>) {
      await dispatch(onSuccess, dataContext: dataContext);
    }
  }

  Future<void> _handleReloadRequest(Map<String, dynamic> action) async {
    final requestKey = action['requestKey'] as String?;
    if (requestKey == null || requestKey.isEmpty) {
      AppLogger.debug('[ActionDispatcher] reloadRequest: missing requestKey');
      return;
    }

    final reload = _pageStateStore?.reloadRequest;
    if (reload == null) {
      AppLogger.debug(
        '[ActionDispatcher] reloadRequest: no handler for $requestKey',
      );
      return;
    }

    await reload(requestKey);
  }

  bool _passesAuthGate(
    Map<String, dynamic> action, {
    Map<String, dynamic>? dataContext,
  }) {
    if (action['requireAuth'] != true) return true;
    final token =
        getIt.isRegistered<TokenCubit>() ? getIt<TokenCubit>().state : null;
    if (AuthRedirect.isLoggedIn(token)) return true;

    final onUnauthenticated = action['onUnauthenticated'];
    if (onUnauthenticated is Map<String, dynamic>) {
      dispatch(onUnauthenticated, dataContext: dataContext);
      return false;
    }

    AuthPromptSheet.show(_context);
    return false;
  }

  Future<void> _handleOpenUrl(
    Map<String, dynamic> action, {
    Map<String, dynamic>? dataContext,
  }) async {
    final resolver = ActionValueResolver(formState: _formState);
    final urlPath = action['urlPath'] as String?;
    final url = resolver.resolveString(action['url'], dataContext: dataContext) ??
        (urlPath != null && urlPath.isNotEmpty
            ? resolveDataContextPath(dataContext, urlPath)?.toString().trim()
            : null);
    if (url == null || url.isEmpty) {
      AppLogger.debug('[ActionDispatcher] openUrl: missing url');
      return;
    }
    await _launchExternal(Uri.parse(url));
  }

  Future<void> _handleOpenContact(
    Map<String, dynamic> action, {
    Map<String, dynamic>? dataContext,
  }) async {
    final channel =
        (action['channel'] as String? ?? 'whatsapp').toLowerCase();
    final resolver = ActionValueResolver(formState: _formState);
    final target = resolver.resolveString(action['target'], dataContext: dataContext);
    if (target == null || target.isEmpty) {
      AppLogger.debug('[ActionDispatcher] openContact: missing target');
      return;
    }
    final uriString = ContactUriBuilder.buildUri(channel: channel, target: target);
    if (uriString == null || uriString.isEmpty) {
      AppLogger.debug('[ActionDispatcher] openContact: invalid target for $channel');
      return;
    }
    await _launchExternal(Uri.parse(uriString));
  }

  Future<void> _launchExternal(Uri uri) async {
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        AppLogger.debug('[ActionDispatcher] launchUrl returned false for $uri');
      }
    } catch (e) {
      AppLogger.debug('[ActionDispatcher] launchUrl failed: $e');
    }
  }

  void _handleDrawer(
    Map<String, dynamic> action, {
    required bool open,
    Map<String, dynamic>? dataContext,
  }) {
    final edge = (action['drawerEdge'] as String?)?.toLowerCase();
    final ctx = dataContext ?? _dataContext;
    final registry = ctx?[EnginePageChromeRegistry.contextKey];
    if (registry is EnginePageChromeRegistry) {
      final useEnd = edge == 'end' || registry.drawerEdge.toLowerCase() == 'end';
      final state = registry.scaffoldKey.currentState;
      if (state != null) {
        if (open) {
          if (useEnd) {
            state.openEndDrawer();
          } else {
            state.openDrawer();
          }
        } else {
          if (useEnd) {
            state.closeEndDrawer();
          } else {
            state.closeDrawer();
          }
        }
        return;
      }
    }

    final scaffoldState = Scaffold.maybeOf(_context);
    if (scaffoldState == null) return;

    final useEnd = edge == 'end';
    if (open) {
      if (useEnd) {
        scaffoldState.openEndDrawer();
      } else {
        scaffoldState.openDrawer();
      }
    } else {
      if (useEnd) {
        scaffoldState.closeEndDrawer();
      } else {
        scaffoldState.closeDrawer();
      }
    }
  }

  void _closeDrawerIfOpen(Map<String, dynamic>? dataContext) {
    final ctx = dataContext ?? _dataContext;
    final registry = ctx?[EnginePageChromeRegistry.contextKey];
    if (registry is! EnginePageChromeRegistry) return;
    final state = registry.scaffoldKey.currentState;
    if (state == null) return;
    if (registry.drawerEdge.toLowerCase() == 'end') {
      state.closeEndDrawer();
    } else {
      state.closeDrawer();
    }
  }

  void _handleNavigate(
    Map<String, dynamic> action, {
    Map<String, dynamic>? dataContext,
  }) {
    _closeDrawerIfOpen(dataContext);
    final route = action['route'] as String?;
    if (route == null || route.isEmpty) return;
    final resolvedRoute = _resolveRoute(route, dataContext);
    final requestedType = parseNavigationType(
      action['navigation_type'] as String?,
    );
    final tabRoutes = _tabRoutesFromConfig();
    final navType = AppNavigation.resolveForRoute(
      route: resolvedRoute,
      requested: requestedType,
      tabRoutes: tabRoutes,
    );
    if (navType != requestedType) {
      AppLogger.debug(
        '[ActionDispatcher] push downgraded to go for tab route $resolvedRoute',
      );
    }
    AppLogger.debug('[ActionDispatcher] navigate to $resolvedRoute');
    AppNavigation.navigate(
      _context,
      route: resolvedRoute,
      type: navType,
      tabRoutes: tabRoutes,
    );
  }

  Set<String> _tabRoutesFromConfig() {
    final config = registeredMobileAppConfig;
    if (config == null || !config.navigation.hasTabs) {
      return const {};
    }
    return config.navigation.tabs.map((tab) => tab.route).toSet();
  }

  String _resolveRoute(String route, Map<String, dynamic>? dataContext) {
    return route.replaceAllMapped(RegExp(r':([A-Za-z0-9_]+)'), (match) {
      final key = match.group(1) ?? '';
      final value = _lookupRouteValue(key, dataContext);
      return value ?? match.group(0) ?? '';
    });
  }

  String? _lookupRouteValue(String key, Map<String, dynamic>? dataContext) {
    if (dataContext == null || key.isEmpty) return null;

    final routeParams = dataContext['routeParams'];
    if (routeParams is Map<String, dynamic>) {
      final fromRoute = routeParams[key];
      if (fromRoute != null) return fromRoute.toString();
    }

    final direct = dataContext[key];
    if (direct != null) return direct.toString();

    final item = dataContext['item'];
    if (item is Map<String, dynamic>) {
      if (key == 'productId') {
        final slug = item['slug'];
        if (slug != null && slug.toString().trim().isNotEmpty) {
          return slug.toString().trim();
        }
      }

      dynamic itemValue = item[key];
      if (itemValue == null && key == 'productId') {
        itemValue = item['slug'] ?? item['id'] ?? item['productId'];
      } else if (itemValue == null && key == 'slug') {
        itemValue = item['slug'];
      } else if (itemValue == null && key == 'categorySlug') {
        itemValue = item['slug'] ?? item['categoryId'];
      } else if (itemValue == null && key == 'orderId') {
        itemValue = item['orderId'];
      } else if (itemValue == null && key == 'id') {
        itemValue = item['productId'] ?? item['orderId'];
      }
      if (itemValue != null) return itemValue.toString();
    }

    if (key == 'orderId') {
      final order = dataContext['order'];
      if (order is Map<String, dynamic>) {
        final fromOrder = order['lastLookupOrderId'];
        if (fromOrder != null && fromOrder.toString().trim().isNotEmpty) {
          return fromOrder.toString();
        }
      }
      final checkout = dataContext['checkout'];
      if (checkout is Map<String, dynamic>) {
        final lastOrder = checkout['lastOrder'];
        if (lastOrder is Map<String, dynamic>) {
          final id = lastOrder['orderId'];
          if (id != null && id.toString().trim().isNotEmpty) {
            return id.toString();
          }
        }
      }
    }

    return null;
  }

  Future<void> _handleApiCall(
    Map<String, dynamic> action, {
    String? value,
    String? fieldId,
  }) async {
    final endpoint = action['endpoint'] as String?;
    final method = (action['method'] as String?)?.toLowerCase();
    if (endpoint == null || endpoint.isEmpty || method == null) return;

    final api = getIt<ApiService>();
    final payload = _buildPayload(action['body'], value, fieldId);

    try {
      switch (method) {
        case 'get':
          await api.get(
            url: endpoint,
            token: null,
            body: payload,
            queryParameters: action['query'] as Map<String, dynamic>?,
          );
          break;
        case 'post':
          await api.post(url: endpoint, body: payload, token: null);
          break;
        case 'put':
          await api.put(url: endpoint, body: payload, token: null);
          break;
        case 'delete':
          await api.delete(url: endpoint, body: payload, token: null);
          break;
        default:
          AppLogger.debug(
            '[ActionDispatcher] Unsupported apiCall method: $method',
          );
      }
    } catch (e) {
      AppLogger.debug('[ActionDispatcher] apiCall failed: $e');
    }
  }

  Future<void> _handleCubitCall(
    Map<String, dynamic> action, {
    Map<String, dynamic>? dataContext,
  }) async {
    final cubitName = (action['cubit'] as String?)?.toLowerCase();
    final method = action['method'] as String?;
    if (cubitName == null || method == null) {
      return;
    }

    switch (cubitName) {
      case 'auth':
        await _handleAuthCubitCall(action, method: method, dataContext: dataContext);
        return;
      case 'cart':
        await _handleCartCubitCall(action, method: method, dataContext: dataContext);
        return;
      case 'checkout':
        await _handleCheckoutCubitCall(
          action,
          method: method,
          dataContext: dataContext,
        );
        return;
      case 'order':
        await _handleOrderCubitCall(
          action,
          method: method,
          dataContext: dataContext,
        );
        return;
      case 'wishlist':
        await _handleWishlistCubitCall(
          action,
          method: method,
          dataContext: dataContext,
        );
        return;
      default:
        AppLogger.debug('[ActionDispatcher] Unsupported cubit: $cubitName');
        return;
    }
  }

  Future<void> _handleAuthCubitCall(
    Map<String, dynamic> action, {
    required String method,
    Map<String, dynamic>? dataContext,
  }) async {
    final authCubit = getIt<AuthCubit>();
    final params = _resolveCubitParams(
      action['params'] as Map<String, dynamic>?,
      dataContext: dataContext,
      authState: authCubit.state,
    );

    AppLogger.auth(
      'cubitCall method=$method resolvedParams=$params '
      'appContext=${dataContext?['app']}',
    );

    try {
      switch (method) {
        case 'requestOtp':
          await authCubit.requestOtp(
            phone: params['phone'] as String? ?? '',
            tenantId: params['tenantId'] as String?,
            tenantSlug: params['tenantSlug'] as String?,
            fullName: params['fullName'] as String?,
          );
          break;
        case 'verifyOtp':
          await authCubit.verifyOtp(
            phone: params['phone'] as String? ?? '',
            otpCode: params['otpCode'] as String? ?? '',
            tenantId: params['tenantId'] as String?,
            tenantSlug: params['tenantSlug'] as String?,
            totpCode: params['totpCode'] as String?,
            backupCode: params['backupCode'] as String?,
          );
          break;
        case 'logout':
          await authCubit.logout();
          break;
        default:
          AppLogger.debug('[ActionDispatcher] Unsupported auth method: $method');
          return;
      }

      final state = authCubit.state;
      if (state is AuthFailureState || state is AuthRateLimited) {
        final onFailure = action['onFailure'];
        if (onFailure is Map<String, dynamic>) {
          await dispatch(onFailure, dataContext: dataContext);
        }
        return;
      }

      if (_isAuthSuccessState(state, method)) {
        final onSuccess = action['onSuccess'];
        if (onSuccess is Map<String, dynamic>) {
          await dispatch(onSuccess, dataContext: dataContext);
        }
      }
    } catch (e) {
      AppLogger.debug('[ActionDispatcher] cubitCall failed: $e');
    }
  }

  Future<void> _handleCartCubitCall(
    Map<String, dynamic> action, {
    required String method,
    Map<String, dynamic>? dataContext,
  }) async {
    if (!getIt.isRegistered<CartCubit>()) {
      AppLogger.debug('[ActionDispatcher] CartCubit not registered');
      return;
    }

    final cartCubit = getIt<CartCubit>();
    final params = _resolveCubitParams(
      action['params'] as Map<String, dynamic>?,
      dataContext: dataContext,
    );

    try {
      switch (method) {
        case 'addItem':
          await cartCubit.addItem(
            variantId: params['variantId']?.toString() ?? '',
            productTitle: params['productTitle']?.toString() ?? '',
            quantity: _parseIntParam(params['quantity'], fallback: 1) ?? 1,
            variantTitle: params['variantTitle']?.toString(),
            unitPrice: parseSypAmount(params['unitPrice']),
            thumbnailUrl: params['thumbnailUrl']?.toString(),
          );
          break;
        case 'updateQuantity':
          await cartCubit.updateQuantity(
            variantId: params['variantId']?.toString() ?? '',
            quantity: _parseIntParam(params['quantity']),
            delta: _parseIntParam(params['delta']),
          );
          break;
        case 'removeItem':
          await cartCubit.removeItem(
            variantId: params['variantId']?.toString() ?? '',
          );
          break;
        case 'clear':
          await cartCubit.clear();
          break;
        case 'assertNotEmpty':
          await cartCubit.assertNotEmpty();
          break;
        default:
          AppLogger.debug('[ActionDispatcher] Unsupported cart method: $method');
          return;
      }

      final state = cartCubit.state;
      if (state is CartFailureState) {
        final onFailure = action['onFailure'];
        if (onFailure is Map<String, dynamic>) {
          await dispatch(onFailure, dataContext: dataContext);
        }
        return;
      }

      if (state is CartLoaded || state is CartActionSuccess) {
        final onSuccess = action['onSuccess'];
        if (onSuccess is Map<String, dynamic>) {
          await dispatch(onSuccess, dataContext: dataContext);
        }
      }
    } catch (e) {
      AppLogger.debug('[ActionDispatcher] cart cubitCall failed: $e');
    }
  }

  Future<void> _handleWishlistCubitCall(
    Map<String, dynamic> action, {
    required String method,
    Map<String, dynamic>? dataContext,
  }) async {
    if (!getIt.isRegistered<WishlistCubit>()) {
      AppLogger.debug('[ActionDispatcher] WishlistCubit not registered');
      return;
    }

    final wishlistCubit = getIt<WishlistCubit>();
    final params = _resolveCubitParams(
      action['params'] as Map<String, dynamic>?,
      dataContext: dataContext,
    );

    try {
      switch (method) {
        case 'toggle':
          await wishlistCubit.toggle(
            productId: params['productId']?.toString() ?? '',
            productTitle: params['productTitle']?.toString() ?? '',
            thumbnailUrl: params['thumbnailUrl']?.toString(),
            displayPrice: params['displayPrice']?.toString(),
          );
          break;
        case 'add':
          await wishlistCubit.add(
            productId: params['productId']?.toString() ?? '',
            productTitle: params['productTitle']?.toString() ?? '',
            thumbnailUrl: params['thumbnailUrl']?.toString(),
            displayPrice: params['displayPrice']?.toString(),
          );
          break;
        case 'remove':
          await wishlistCubit.remove(
            productId: params['productId']?.toString() ?? '',
          );
          break;
        case 'clear':
          await wishlistCubit.clear();
          break;
        default:
          AppLogger.debug(
            '[ActionDispatcher] Unsupported wishlist method: $method',
          );
          return;
      }

      final state = wishlistCubit.state;
      if (state is WishlistFailureState) {
        final onFailure = action['onFailure'];
        if (onFailure is Map<String, dynamic>) {
          await dispatch(onFailure, dataContext: dataContext);
        }
        return;
      }

      if (state is WishlistLoaded || state is WishlistActionSuccess) {
        final onSuccess = action['onSuccess'];
        if (onSuccess is Map<String, dynamic>) {
          await dispatch(onSuccess, dataContext: dataContext);
        }
      }
    } catch (e) {
      AppLogger.debug('[ActionDispatcher] wishlist cubitCall failed: $e');
    }
  }

  Future<void> _handleCheckoutCubitCall(
    Map<String, dynamic> action, {
    required String method,
    Map<String, dynamic>? dataContext,
  }) async {
    if (!getIt.isRegistered<CheckoutCubit>()) {
      AppLogger.debug('[ActionDispatcher] CheckoutCubit not registered');
      return;
    }

    final checkoutCubit = getIt<CheckoutCubit>();
    final params = _resolveCubitParams(
      action['params'] as Map<String, dynamic>?,
      dataContext: dataContext,
    );

    try {
      switch (method) {
        case 'pickLocation':
          await checkoutCubit.pickLocation(_context);
          break;
        case 'saveAddress':
          await checkoutCubit.saveAddress(
            recipientName: params['recipientName']?.toString() ?? '',
            phone: params['phone']?.toString() ?? '',
            addressLabel: params['addressLabel']?.toString(),
            guestEmail: params['guestEmail']?.toString(),
            notesCustomer: params['notesCustomer']?.toString(),
          );
          break;
        case 'selectPaymentMethod':
          await checkoutCubit.selectPaymentMethod(
            providerCode: params['providerCode']?.toString() ??
                params['value']?.toString() ??
                '',
          );
          break;
        case 'validateDiscount':
          await checkoutCubit.validateDiscount(
            code: params['code']?.toString() ?? '',
          );
          return;
        case 'placeOrder':
          if (getIt.isRegistered<CartCubit>()) {
            await getIt<CartCubit>().assertNotEmpty();
            final cartState = getIt<CartCubit>().state;
            if (cartState is CartFailureState) {
              final onFailure = action['onFailure'];
              if (onFailure is Map<String, dynamic>) {
                await dispatch(onFailure, dataContext: dataContext);
              }
              return;
            }
          }
          await checkoutCubit.placeOrder();
          break;
        default:
          AppLogger.debug(
            '[ActionDispatcher] Unsupported checkout method: $method',
          );
          return;
      }

      if (method == 'validateDiscount') {
        return;
      }

      final state = checkoutCubit.state;
      if (state is CheckoutFailureState) {
        final onFailure = action['onFailure'];
        if (onFailure is Map<String, dynamic>) {
          await dispatch(onFailure, dataContext: dataContext);
        }
        return;
      }

      if (state is CheckoutLoaded || state is CheckoutActionSuccess) {
        final onSuccess = action['onSuccess'];
        if (onSuccess is Map<String, dynamic>) {
          await dispatch(onSuccess, dataContext: dataContext);
        }
      }
    } catch (e) {
      AppLogger.debug('[ActionDispatcher] checkout cubitCall failed: $e');
    }
  }

  Future<void> _handleOrderCubitCall(
    Map<String, dynamic> action, {
    required String method,
    Map<String, dynamic>? dataContext,
  }) async {
    if (!getIt.isRegistered<OrderCubit>()) {
      AppLogger.debug('[ActionDispatcher] OrderCubit not registered');
      return;
    }

    final orderCubit = getIt<OrderCubit>();
    final params = _resolveCubitParams(
      action['params'] as Map<String, dynamic>?,
      dataContext: dataContext,
    );

    try {
      switch (method) {
        case 'lookupGuest':
          await orderCubit.lookupGuest(
            orderNumber: params['orderNumber']?.toString() ?? '',
            email: params['email']?.toString() ?? '',
          );
          final lookupState = orderCubit.state;
          if (lookupState is OrderGuestLookupUpdated &&
              lookupState.lastLookupOrderId != null &&
              lookupState.guestLookupError == null) {
            final merged = Map<String, dynamic>.from(dataContext ?? {});
            _mergeOrderSession(merged, orderCubit);
            final onSuccess = action['onSuccess'];
            if (onSuccess is Map<String, dynamic>) {
              await dispatch(onSuccess, dataContext: merged);
            }
          }
          return;
        case 'cancelOrder':
          await orderCubit.cancelOrder(
            orderId: params['orderId']?.toString() ?? '',
            reason: params['reason']?.toString(),
          );
          break;
        case 'openInvoice':
          await orderCubit.openInvoice(params['orderId']?.toString() ?? '');
          return;
        default:
          AppLogger.debug(
            '[ActionDispatcher] Unsupported order method: $method',
          );
          return;
      }

      final state = orderCubit.state;
      if (state is OrderFailureState) {
        final onFailure = action['onFailure'];
        if (onFailure is Map<String, dynamic>) {
          await dispatch(onFailure, dataContext: dataContext);
        }
        return;
      }

      if (state is OrderActionSuccess) {
        final onSuccess = action['onSuccess'];
        if (onSuccess is Map<String, dynamic>) {
          await dispatch(onSuccess, dataContext: dataContext);
        }
      }
    } catch (e) {
      AppLogger.debug('[ActionDispatcher] order cubitCall failed: $e');
    }
  }

  void _mergeOrderSession(Map<String, dynamic> ctx, OrderCubit cubit) {
    ctx['order'] = <String, dynamic>{
      if (cubit.guestLookupError != null) 'guestLookupError': cubit.guestLookupError,
      if (cubit.lastLookupOrderId != null)
        'lastLookupOrderId': cubit.lastLookupOrderId,
    };
    if (cubit.lastLookupOrderId != null) {
      ctx['orderId'] = cubit.lastLookupOrderId;
    }
  }

  int? _parseIntParam(dynamic raw, {int? fallback}) {
    final parsed = parseSypAmount(raw);
    if (parsed != null) return parsed;
    if (fallback != null) return fallback;
    return null;
  }

  bool _isAuthSuccessState(AuthState state, String method) {
    return switch (method) {
      'requestOtp' => state is AuthOtpRequested,
      'verifyOtp' => state is AuthAuthenticated,
      'logout' => state is AuthInitial,
      _ => false,
    };
  }

  Map<String, dynamic> _resolveCubitParams(
    Map<String, dynamic>? params, {
    Map<String, dynamic>? dataContext,
    AuthState? authState,
  }) {
    if (params == null || params.isEmpty) {
      return const {};
    }

    final resolved = <String, dynamic>{};
    for (final entry in params.entries) {
      final spec = entry.value;
      if (spec is! Map) {
        resolved[entry.key] = spec;
        continue;
      }
      final source = (spec['source'] as String?)?.toLowerCase();
      final field = spec['field'] as String?;
      switch (source) {
        case 'form':
          if (field != null && _formState != null) {
            resolved[entry.key] = _formState.valueFor(field);
          }
        case 'app':
          if (field != null && dataContext != null) {
            final app = dataContext['app'];
            if (app is Map<String, dynamic>) {
              resolved[entry.key] = app[field];
            }
          }
        case 'authstate':
          if (authState != null) {
            resolved[entry.key] = _readAuthStateField(authState, field);
          }
        case 'item':
          if (field != null && dataContext != null) {
            final item = dataContext['item'];
            if (item is Map) {
              resolved[entry.key] = item[field];
            }
          }
        case 'routeparams':
        case 'route_params':
          if (field != null && dataContext != null) {
            final routeParams = dataContext['routeParams'];
            if (routeParams is Map) {
              resolved[entry.key] = routeParams[field];
            }
          }
        case 'datacontext':
        case 'context':
          if (field != null && field.isNotEmpty && dataContext != null) {
            final path = field.startsWith('dataContext.')
                ? field
                : 'dataContext.$field';
            resolved[entry.key] = resolveDataContextPath(dataContext, path);
          }
        case 'tap':
          if (field != null && dataContext != null) {
            final tap = dataContext['tap'];
            if (tap is Map && tap.containsKey(field)) {
              resolved[entry.key] = tap[field];
            }
          }
        case 'pagestate':
        case 'page_state':
          if (field != null) {
            final store = _pageStateStore ??
                (dataContext?[PageStateStore.contextKey] as PageStateStore?);
            if (store != null && store.values.containsKey(field)) {
              resolved[entry.key] = store.values[field];
            } else if (dataContext != null) {
              final fromContext = resolveDataContextPath(
                dataContext,
                field.startsWith('pageState.') ? field : 'pageState.$field',
              );
              if (fromContext != null) {
                resolved[entry.key] = fromContext;
              }
            }
          }
        case 'value':
          resolved[entry.key] = spec['value'];
        default:
          resolved[entry.key] = spec['value'];
      }
    }

    _applyNetworkConfigFallbacks(resolved);
    return resolved;
  }

  void _applyNetworkConfigFallbacks(Map<String, dynamic> resolved) {
    if (!getIt.isRegistered<NetworkConfig>()) {
      return;
    }
    final network = getIt<NetworkConfig>();
    final slug = resolved['tenantSlug'];
    if ((slug == null || (slug is String && slug.isEmpty)) &&
        network.tenantSlug != null) {
      resolved['tenantSlug'] = network.tenantSlug;
      AppLogger.auth('tenantSlug fallback from NetworkConfig: ${network.tenantSlug}');
    }

    final tenantId = resolved['tenantId'];
    if ((tenantId == null || (tenantId is String && tenantId.isEmpty)) &&
        network.tenantId != null) {
      resolved['tenantId'] = network.tenantId;
      AppLogger.auth('tenantId fallback from NetworkConfig: ${network.tenantId}');
    }
  }

  dynamic _readAuthStateField(AuthState state, String? field) {
    if (field == null) {
      return null;
    }
    return switch (state) {
      AuthRequestingOtp(:final phone) when field == 'phone' => phone,
      AuthRequestingOtp(:final tenantId) when field == 'tenantId' => tenantId,
      AuthRequestingOtp(:final tenantSlug) when field == 'tenantSlug' => tenantSlug,
      AuthOtpRequested(:final phone) when field == 'phone' => phone,
      AuthOtpRequested(:final tenantId) when field == 'tenantId' => tenantId,
      AuthOtpRequested(:final tenantSlug) when field == 'tenantSlug' => tenantSlug,
      AuthOtpRequested(:final fullName) when field == 'fullName' => fullName,
      AuthVerifyingOtp(:final phone) when field == 'phone' => phone,
      AuthVerifyingOtp(:final tenantId) when field == 'tenantId' => tenantId,
      AuthVerifyingOtp(:final tenantSlug) when field == 'tenantSlug' => tenantSlug,
      _ => null,
    };
  }

  dynamic _buildPayload(dynamic body, String? value, String? fieldId) {
    final includeFormValues = body is Map<String, dynamic>
        ? body['includeFormValues'] == true
        : false;
    final isMap = body is Map<String, dynamic>;
    if (!isMap && !includeFormValues) return body;
    final next = isMap ? Map<String, dynamic>.from(body) : <String, dynamic>{};
    next.remove('includeFormValues');
    if (fieldId != null && fieldId.isNotEmpty && value != null) {
      next.putIfAbsent(fieldId, () => value);
    }
    if (includeFormValues && _formState != null) {
      next['form'] = _formState.snapshot();
    }
    return next;
  }
}
