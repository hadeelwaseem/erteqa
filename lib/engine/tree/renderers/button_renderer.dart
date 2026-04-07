import 'package:flutter/material.dart';

import '../../../config/genericConfig/component_config.dart';
import 'component_renderer.dart';
import '../parsers/property_parsers.dart';

class ButtonRenderer implements ComponentRenderer {
  @override
  Widget render(
    ComponentConfig config, {
    required ComponentWidgetBuilder buildChild,
    Map<String, dynamic>? dataContext,
  }) {
    final label = config.properties['label'] as String? ?? '';
    final backgroundColor = PropertyParsers.parseColor(
      config.properties['backgroundColor'] as String?,
    );
    final borderRadius = PropertyParsers.parseBorderRadius(
      config.properties['borderRadius'],
    );
    final padding = PropertyParsers.parseEdgeInsets(
      config.properties['padding'],
    );
    final alignment = PropertyParsers.parseAlignment(
      config.properties['alignment'] as String?,
    );

    final button = ElevatedButton(
      onPressed: () {},
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        padding:
            padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: borderRadius ?? BorderRadius.circular(8),
        ),
      ),
      child: Text(label),
    );

    if (alignment != null) {
      return Align(alignment: alignment, child: button);
    }
    return button;
  }
}
