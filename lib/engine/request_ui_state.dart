import 'package:flutter/material.dart';

/// Contract for request-bound list/grid UI (see VariantScreen [dataContext]):
///
/// - `requests.{requestKey}` — API payload map (`success`, `message`, `data`, …)
/// - `loadingRequestKeys` — `Map<String, bool>` for initial load in progress
/// - `initialRequestKeys` — keys dispatched on page load (excludes `qField` deferrals)
/// - `loadingMoreRequests` — load-more footer (scaffold only)
///
/// Component props: `requestKey` or `data.requestKey`, optional `emptyMessage` /
/// `errorMessage`.

/// Phase for a list/grid bound to a [requestKey].
enum RequestBoundListPhase {
  /// No requestKey — render items/children as today.
  none,

  /// Initial load or request not yet in [dataContext].
  loading,

  /// `requests[key].success == false`.
  error,

  /// Success (or unset success) with zero resolved items.
  empty,

  /// Data available to build the list/grid.
  ready,
}

/// Resolves `props.requestKey` then `props.data.requestKey` (production pattern).
String? resolveRequestKey(Map<String, dynamic>? props) {
  if (props == null || props.isEmpty) {
    return null;
  }
  final topLevel = props['requestKey'];
  if (topLevel is String && topLevel.isNotEmpty) {
    return topLevel;
  }
  final data = props['data'];
  if (data is Map<String, dynamic>) {
    final nested = data['requestKey'];
    if (nested is String && nested.isNotEmpty) {
      return nested;
    }
  }
  return null;
}

bool _isLoadingKey(Map<String, dynamic>? dataContext, String requestKey) {
  final loading = dataContext?['loadingRequestKeys'];
  if (loading is Map) {
    return loading[requestKey] == true;
  }
  return false;
}

Map<String, dynamic>? requestMapForKey(
  Map<String, dynamic>? dataContext,
  String requestKey,
) {
  final requests = dataContext?['requests'];
  if (requests is! Map) {
    return null;
  }
  final entry = requests[requestKey];
  if (entry is Map<String, dynamic>) {
    return entry;
  }
  if (entry is Map) {
    return Map<String, dynamic>.from(entry);
  }
  return null;
}

bool _isInitialPageRequest(
  Map<String, dynamic>? dataContext,
  String requestKey,
) {
  final initial = dataContext?['initialRequestKeys'];
  if (initial is Map) {
    return initial[requestKey] == true;
  }
  return false;
}

/// Derives loading / error / empty / ready from [dataContext] and [requestKey].
RequestBoundListPhase resolveRequestBoundListPhase({
  required String? requestKey,
  required Map<String, dynamic>? dataContext,
  required bool itemsEmpty,
}) {
  if (requestKey == null || requestKey.isEmpty) {
    return RequestBoundListPhase.none;
  }

  if (_isLoadingKey(dataContext, requestKey)) {
    return RequestBoundListPhase.loading;
  }

  final request = requestMapForKey(dataContext, requestKey);
  if (request == null) {
    // Absent + initial page fetch (non-qField) → loading (avoids empty flash).
    // Absent + deferred qField search → none (caller shows static empty/children).
    if (_isInitialPageRequest(dataContext, requestKey)) {
      return RequestBoundListPhase.loading;
    }
    return RequestBoundListPhase.none;
  }

  if (request['success'] == false) {
    return RequestBoundListPhase.error;
  }

  if (itemsEmpty) {
    return RequestBoundListPhase.empty;
  }

  return RequestBoundListPhase.ready;
}

/// Message for error/empty: [prop] if set, else request `message`, else [fallback].
String resolveDisplayMessage({
  String? prop,
  Map<String, dynamic>? requestMap,
  required String fallback,
}) {
  if (prop != null && prop.trim().isNotEmpty) {
    return prop;
  }
  final fromRequest = requestMap?['message'];
  if (fromRequest is String && fromRequest.trim().isNotEmpty) {
    return fromRequest;
  }
  return fallback;
}

const String kDefaultEmptyMessage = 'لا توجد عناصر';
const String kDefaultErrorMessage = 'تعذر تحميل المحتوى';

/// True when a successful request has no usable [data] payload yet.
bool isRequestPayloadEmpty(Map<String, dynamic>? requestMap) {
  if (requestMap == null) {
    return true;
  }
  if (requestMap['success'] == false) {
    return false;
  }
  final data = requestMap['data'];
  if (data == null) {
    return true;
  }
  if (data is Map && data.isEmpty) {
    return true;
  }
  return false;
}

/// Placeholder for loading, error, or empty phases on list/grid/container.
Widget buildRequestPhasePlaceholder({
  required RequestBoundListPhase phase,
  required String message,
  bool compact = false,
}) {
  if (phase == RequestBoundListPhase.none ||
      phase == RequestBoundListPhase.ready) {
    return const SizedBox.shrink();
  }

  if (compact) {
    return switch (phase) {
      RequestBoundListPhase.loading => const SizedBox(
        height: 72,
        child: Center(
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
        ),
      ),
      RequestBoundListPhase.error || RequestBoundListPhase.empty =>
        const SizedBox.shrink(),
      _ => const SizedBox.shrink(),
    };
  }

  return switch (phase) {
    RequestBoundListPhase.loading => const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 48, horizontal: 24),
        child: CircularProgressIndicator(),
      ),
    ),
    RequestBoundListPhase.error => Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
        child: _RequestPhaseMessage(
          icon: Icons.error_outline,
          iconColor: Color(0xFFDC2626),
          message: message,
        ),
      ),
    ),
    RequestBoundListPhase.empty => Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
        child: _RequestPhaseMessage(
          icon: Icons.inventory_2_outlined,
          iconColor: Color(0xFF94A3B8),
          message: message,
        ),
      ),
    ),
    _ => const SizedBox.shrink(),
  };
}

class _RequestPhaseMessage extends StatelessWidget {
  const _RequestPhaseMessage({
    required this.icon,
    required this.iconColor,
    required this.message,
  });

  final IconData icon;
  final Color iconColor;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 48, color: iconColor),
        const SizedBox(height: 12),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF475569),
            height: 1.4,
          ),
        ),
      ],
    );
  }
}
