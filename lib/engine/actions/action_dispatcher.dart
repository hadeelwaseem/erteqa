import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../core/utils/api_service.dart';
import '../../core/utils/app_logger.dart';
import '../../core/utils/service_locator.dart';

class EngineActionDispatcher {
  static const contextKey = '_engineActionDispatcher';

  EngineActionDispatcher({required BuildContext context}) : _context = context;

  final BuildContext _context;

  VoidCallback? resolveTap(Map<String, dynamic>? action) {
    if (action == null) return null;
    return () => dispatch(action);
  }

  Future<void> dispatch(
    Map<String, dynamic> action, {
    String? value,
    String? fieldId,
  }) async {
    final type = action['type'] as String?;
    switch (type) {
      case 'navigate':
        _handleNavigate(action);
        return;
      case 'apiCall':
        await _handleApiCall(action, value: value, fieldId: fieldId);
        return;
      default:
        AppLogger.debug('[ActionDispatcher] Unsupported action type: $type');
        return;
    }
  }

  void _handleNavigate(Map<String, dynamic> action) {
    final route = action['route'] as String?;
    if (route == null || route.isEmpty) return;
    AppLogger.debug('[ActionDispatcher] navigate to $route');
    _context.go(route);
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
    if (body is! Map<String, dynamic>) return body;
    if (fieldId == null || fieldId.isEmpty || value == null) {
      return body;
    }
    final next = Map<String, dynamic>.from(body);
    next.putIfAbsent(fieldId, () => value);
    return next;
  }
}
