import 'package:flutter/material.dart';

import '../../../config/component_config.dart';
import '../../component_renderer/component_renderer.dart';
import '../parsers/property_parsers.dart';

class IconRenderer implements ComponentRenderer {
  @override
  Widget render(
    ComponentConfig config, {
    required ComponentWidgetBuilder buildChild,
    Map<String, dynamic>? dataContext,
  }) {
    final name = config.properties['name'] as String? ?? '';
    final size = PropertyParsers.parseDouble(config.properties['size']);
    final color = PropertyParsers.parseColor(
      config.properties['color'] as String?,
    );

    return Icon(PropertyParsers.parseIconData(name), size: size, color: color);
  }
}
