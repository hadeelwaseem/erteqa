import 'package:flutter/widgets.dart';

import '../../../config/component_config.dart';

import '../../component_renderer/component_renderer.dart';
import '../parsers/property_parsers.dart';

class ContainerRenderer implements ComponentRenderer {
  @override
  Widget render(
    ComponentConfig config, {
    required ComponentWidgetBuilder buildChild,
    Map<String, dynamic>? dataContext,
  }) {
    final padding = PropertyParsers.parseEdgeInsets(
      config.properties['padding'],
    );
    final margin = PropertyParsers.parseEdgeInsets(config.properties['margin']);
    final color = PropertyParsers.parseColor(
      config.properties['color'] as String?,
    );
    final borderRadius = PropertyParsers.parseBorderRadius(
      config.properties['borderRadius'],
    );
    final child = config.child != null ? buildChild(config.child!) : null;

    return Container(
      padding: padding,
      margin: margin,
      decoration: borderRadius != null && color != null
          ? BoxDecoration(borderRadius: borderRadius, color: color)
          : null,
      color: borderRadius == null ? color : null,
      child: child,
    );
  }
}
