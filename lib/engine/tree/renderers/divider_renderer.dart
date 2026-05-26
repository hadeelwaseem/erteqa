import 'package:flutter/material.dart';

import '../../../config/component_config.dart';
import '../../component_renderer/component_renderer.dart';
import '../parsers/property_parsers.dart';

class DividerRenderer implements ComponentRenderer {
  @override
  Widget render(
    ComponentConfig config, {
    required ComponentWidgetBuilder buildChild,
    Map<String, dynamic>? dataContext,
  }) {
    final height = PropertyParsers.parseDouble(config.properties['height']);
    final thickness = PropertyParsers.parseDouble(
      config.properties['thickness'],
    );
    final color = PropertyParsers.parseColor(
      config.properties['color'] as String?,
    );
    final margin = PropertyParsers.parseEdgeInsets(config.properties['margin']);

    Widget divider = Divider(
      height: height,
      thickness: thickness,
      color: color,
    );

    if (margin != null) {
      divider = Padding(padding: margin, child: divider);
    }

    return divider;
  }
}
