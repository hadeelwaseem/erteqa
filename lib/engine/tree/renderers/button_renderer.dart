import 'package:flutter/material.dart';

import '../../../config/component_config.dart';
import '../../component_renderer/component_renderer.dart';
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
    final textColor = PropertyParsers.parseColor(
      config.properties['textColor'] as String?,
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
    final onTap = config.properties['onTap'] as VoidCallback?;

    final button = ElevatedButton(
      onPressed: onTap ?? () {},
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        padding:
            padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: borderRadius ?? BorderRadius.circular(8),
        ),
      ),
      child: Text(
        label,
        style: textColor != null ? TextStyle(color: textColor) : null,
      ),
    );

    if (alignment != null) {
      return Align(alignment: alignment, child: button);
    }
    return button;
  }
}
