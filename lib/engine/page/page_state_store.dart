import 'package:flutter/foundation.dart';

/// Mutable page-scoped UI state (tab filters, selection keys) for SDUI orchestration.
///
/// Injected into [dataContext] under [contextKey]; also exposed as `pageState` map.
class PageStateStore {
  static const contextKey = '_enginePageState';

  final Map<String, dynamic> values = <String, dynamic>{};

  VoidCallback? onChanged;

  Future<void> Function(String requestKey)? reloadRequest;

  void update(Map<String, dynamic> patch) {
    if (patch.isEmpty) {
      return;
    }
    for (final entry in patch.entries) {
      final value = entry.value;
      if (value == null || (value is String && value.isEmpty)) {
        values.remove(entry.key);
      } else {
        values[entry.key] = value;
      }
    }
    onChanged?.call();
  }

  void clear() {
    if (values.isEmpty) {
      return;
    }
    values.clear();
    onChanged?.call();
  }

  Map<String, dynamic> snapshot() => Map<String, dynamic>.from(values);
}
