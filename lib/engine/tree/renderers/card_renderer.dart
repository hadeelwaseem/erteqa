import 'package:flutter/material.dart';

import '../../../config/genericConfig/component_config.dart';

import 'component_renderer.dart';
import '../parsers/property_parsers.dart';

//TODO: should add flex
class CardRenderer implements ComponentRenderer {
  @override
  Widget render(
    ComponentConfig config, {
    required ComponentWidgetBuilder buildChild,
    Map<String, dynamic>? dataContext,
  }) {
    final elevation =
        (config.properties['elevation'] as num?)?.toDouble() ?? 1.0;
    final borderRadius = PropertyParsers.parseBorderRadius(
      config.properties['borderRadius'],
    );
    final color = PropertyParsers.parseColor(
      config.properties['color'] as String?,
    );
    final child = config.child != null ? buildChild(config.child!) : null;

    return Card(
      elevation: elevation,
      color: color,
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius ?? BorderRadius.circular(4),
      ),
      child: child,
    );
  }
}
