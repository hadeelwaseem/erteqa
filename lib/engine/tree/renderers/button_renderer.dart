import 'package:flutter/material.dart';

import '../../../config/component_config.dart';
import '../../component_renderer/component_renderer.dart';
import '../../theme/engine_theme.dart';
import '../parsers/property_parsers.dart';

class ButtonRenderer implements ComponentRenderer {
  @override
  Widget render(
    ComponentConfig config, {
    required ComponentWidgetBuilder buildChild,
    Map<String, dynamic>? dataContext,
  }) {
    final label = config.properties['label'] as String? ?? '';
    final variant = (config.properties['variant'] as String? ?? 'elevated')
        .toLowerCase();
    final backgroundColor = PropertyParsers.parseColor(
      config.properties['backgroundColor'] as String?,
    );
    final textColor = PropertyParsers.parseColor(
      config.properties['textColor'] as String?,
    );
    final foregroundColor = PropertyParsers.parseColor(
      config.properties['foregroundColor'] as String?,
    );
    final theme = EngineTheme.fromDataContext(dataContext);
    final borderRadius = PropertyParsers.parseBorderRadius(
          config.properties['borderRadius'],
        ) ??
        (theme != null
            ? BorderRadius.circular(theme.buttonMd.radius)
            : const BorderRadius.all(Radius.circular(8)));
    final padding = PropertyParsers.parseEdgeInsets(
      config.properties['padding'],
    );
    final alignment = PropertyParsers.parseAlignment(
      config.properties['alignment'] as String?,
    );
    final onTap = config.properties['onTap'] as VoidCallback?;
    final maxWidth = PropertyParsers.parseDouble(config.properties['maxWidth']);

    final shape = RoundedRectangleBorder(borderRadius: borderRadius);

    late final Widget button;
    switch (variant) {
      case 'text':
        button = TextButton(
          onPressed: onTap ?? () {},
          style: TextButton.styleFrom(
            foregroundColor: foregroundColor ?? textColor,
            padding:
                padding ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            shape: shape,
          ),
          child: Text(
            label,
            style: textColor != null && foregroundColor == null
                ? TextStyle(color: textColor)
                : null,
          ),
        );
        break;
      case 'outlined':
      case 'secondary':
        button = OutlinedButton(
          onPressed: onTap ?? () {},
          style: OutlinedButton.styleFrom(
            foregroundColor: foregroundColor ?? textColor,
            padding:
                padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: shape,
            side: BorderSide(
              color: textColor ?? const Color(0xFF1D4ED8),
            ),
          ),
          child: Text(
            label,
            style: textColor != null && foregroundColor == null
                ? TextStyle(color: textColor)
                : null,
          ),
        );
        break;
      case 'elevated':
      default:
        button = ElevatedButton(
          onPressed: onTap ?? () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: backgroundColor,
            foregroundColor: foregroundColor ?? textColor,
            padding:
                padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: shape,
          ),
          child: Text(
            label,
            style: textColor != null && foregroundColor == null
                ? TextStyle(color: textColor)
                : null,
          ),
        );
    }

    Widget wrapped = button;
    if (maxWidth != null && maxWidth > 0) {
      wrapped = SizedBox(width: maxWidth, child: wrapped);
    }

    if (alignment != null) {
      return Align(alignment: alignment, child: wrapped);
    }
    return wrapped;
  }
}
