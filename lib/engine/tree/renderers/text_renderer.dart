import 'package:flutter/material.dart';

import '../../../config/component_config.dart';

import '../../component_renderer/component_renderer.dart';
import '../parsers/property_parsers.dart';

class TextRenderer implements ComponentRenderer {
  @override
  Widget render(
    ComponentConfig config, {
    required ComponentWidgetBuilder buildChild,
    Map<String, dynamic>? dataContext,
  }) {
    final valuePath = config.properties['valuePath'] as String?;
    final boundValue = _resolvePath(dataContext, valuePath);
    final value =
        (boundValue?.toString().trim().isNotEmpty ?? false)
        ? boundValue.toString()
        : (config.properties['value'] as String? ?? '');
    final fontSize =
        (config.properties['fontSize'] as num?)?.toDouble() ?? 16.0;
    final fontWeight = PropertyParsers.parseFontWeight(
      config.properties['fontWeight'] as String?,
    );
    final color = PropertyParsers.parseColor(
      config.properties['color'] as String?,
    );
    final textAlign = PropertyParsers.parseTextAlign(
      config.properties['textAlign'] as String?,
    );

    return Text(
      value,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        decoration: TextDecoration.none,
      ),
      textAlign: textAlign,
    );
  }

  dynamic _resolvePath(Map<String, dynamic>? root, String? path) {
    if (root == null || path == null || path.isEmpty) return null;

    dynamic current = root;
    for (final segment in path.split('.')) {
      if (current is Map<String, dynamic> && current.containsKey(segment)) {
        current = current[segment];
      } else {
        return null;
      }
    }
    return current;
  }
}
