import 'package:flutter/material.dart';

import '../../../config/component_config.dart';
import '../../component_renderer/component_renderer.dart';
import '../parsers/property_parsers.dart';

/// Renders a [CircularProgressIndicator] for loading states in JSON layouts.
///
/// JSON `props`:
/// - `color` (hex, optional) — stroke color; default theme primary / white context
/// - `strokeWidth` (number, optional) — default 2
/// - `size` (number, optional) — width and height; default 24
class ProgressIndicatorRenderer implements ComponentRenderer {
  @override
  Widget render(
    ComponentConfig config, {
    required ComponentWidgetBuilder buildChild,
    Map<String, dynamic>? dataContext,
  }) {
    final color = PropertyParsers.parseColor(config.properties['color'] as String?);
    final strokeWidth =
        PropertyParsers.parseDouble(config.properties['strokeWidth']) ?? 2;
    final size = PropertyParsers.parseDouble(config.properties['size']) ?? 24;

    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth,
        valueColor: color != null
            ? AlwaysStoppedAnimation<Color>(color)
            : null,
      ),
    );
  }
}
