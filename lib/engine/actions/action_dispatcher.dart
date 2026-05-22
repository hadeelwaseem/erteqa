import 'package:flutter/widgets.dart';

import '../../core/feedback/app_messenger.dart';
import '../../core/navigation/app_navigation.dart';
import '../../core/network/network_config.dart';
import '../../core/utils/api_service.dart';
import '../../core/utils/app_logger.dart';
import '../../core/utils/service_locator.dart';
import '../../features/auth/presentation/manager/auth_cubit/auth_cubit.dart';
import '../form/form_state_store.dart';

class EngineActionDispatcher {
  static const contextKey = '_engineActionDispatcher';

  EngineActionDispatcher({
    required BuildContext context,
    FormStateStore? formState,
    Map<String, dynamic>? dataContext,
  })  : _context = context,
        _formState = formState,
        _dataContext = dataContext;

  final BuildContext _context;
  final FormStateStore? _formState;
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
      default:
        AppLogger.debug('[ActionDispatcher] Unsupported action type: $type');
        return;
    }
  }

  void _handleNavigate(
    Map<String, dynamic> action, {
    Map<String, dynamic>? dataContext,
  }) {
    final route = action['route'] as String?;
    if (route == null || route.isEmpty) return;
    final resolvedRoute = _resolveRoute(route, dataContext);
    final navType = parseNavigationType(action['navigation_type'] as String?);
    AppLogger.debug('[ActionDispatcher] navigate to $resolvedRoute');
    AppNavigation.navigate(_context, route: resolvedRoute, type: navType);
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
      } else if (itemValue == null && key == 'id') {
        itemValue = item['productId'];
      }
      if (itemValue != null) return itemValue.toString();
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

    if (cubitName != 'auth') {
      AppLogger.debug('[ActionDispatcher] Unsupported cubit: $cubitName');
      return;
    }

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

  bool _isAuthSuccessState(AuthState state, String method) {
    return switch (method) {
      'requestOtp' => state is AuthOtpRequested,
      'verifyOtp' => state is AuthAuthenticated,
      _ => false,
    };
  }

  Map<String, dynamic> _resolveCubitParams(
    Map<String, dynamic>? params, {
    Map<String, dynamic>? dataContext,
    required AuthState authState,
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
          resolved[entry.key] = _readAuthStateField(authState, field);
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
