import 'package:flutter/material.dart';

import '../../../config/component_config.dart';
import '../../component_renderer/component_renderer.dart';

/// Renders a placeholder for any component type that does not have a
/// registered renderer.
///
/// In debug mode: logs to console AND shows a visible grey box.
/// In release mode: logs only (no visual noise).
class UnsupportedComponentRenderer implements ComponentRenderer {
  @override
  Widget render(
    ComponentConfig config, {
    required ComponentWidgetBuilder buildChild,
    Map<String, dynamic>? dataContext,
  }) {
    final rawType = config.properties['rawType'] as String? ?? 'unknown';
    final id = config.properties['id'] as String? ?? '(no id)';
    final data = config.properties['data'];
    final source = data is Map ? data['source'] as String? : null;

    final details = source == null
        ? 'type="$rawType" id="$id"'
        : 'type="$rawType" id="$id" source="$source"';

    debugPrint('[Engine] ❌ Unsupported component: $details');

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        border: Border.all(color: Colors.amber.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '⚠️ Unsupported: $rawType${source != null ? ' ($source)' : ''}',
        style: TextStyle(
          color: Colors.amber.shade900,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
