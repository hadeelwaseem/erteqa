import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../core/utils/api_service.dart';
import '../../core/utils/app_logger.dart';
import '../../core/utils/service_locator.dart';
import '../form/form_state_store.dart';

class EngineActionDispatcher {
  static const contextKey = '_engineActionDispatcher';

  EngineActionDispatcher({
    required BuildContext context,
    FormStateStore? formState,
  }) : _context = context,
       _formState = formState;

  final BuildContext _context;
  final FormStateStore? _formState;

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
    final requireValidForm = action['requireValidForm'] == true;
    if (requireValidForm && _formState != null) {
      final formId = action['formId'] as String? ?? '';
      if (!_formState.validate(formId)) {
        return;
      }
    }
    final type = action['type'] as String?;
    switch (type) {
      case 'navigate':
        _handleNavigate(action, dataContext: dataContext);
        return;
      case 'apiCall':
        await _handleApiCall(action, value: value, fieldId: fieldId);
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
    AppLogger.debug('[ActionDispatcher] navigate to $resolvedRoute');
    _context.go(resolvedRoute);
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

    final direct = dataContext[key];
    if (direct != null) return direct.toString();

    final item = dataContext['item'];
    if (item is Map<String, dynamic>) {
      dynamic itemValue = item[key];
      if (itemValue == null && key == 'productId') {
        itemValue = item['id'];
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
