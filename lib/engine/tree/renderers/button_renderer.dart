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
    final enabled = PropertyParsers.parseBool(
      config.properties['enabled'],
      defaultValue: true,
    );
    final onPressed = enabled ? onTap : null;

    final resolvedBackground = backgroundColor ?? theme?.primaryColor;
    final resolvedForeground = foregroundColor ?? textColor;
    final buttonMd = theme?.buttonMd;
    final defaultPadding = buttonMd != null
        ? EdgeInsets.symmetric(
            horizontal: buttonMd.padX,
            vertical: ((buttonMd.height - buttonMd.fontSize) / 2)
                .clamp(8.0, 24.0),
          )
        : const EdgeInsets.symmetric(horizontal: 16, vertical: 12);
    final minimumSize = buttonMd != null
        ? Size(0, buttonMd.height)
        : const Size(64, 48);

    final shape = RoundedRectangleBorder(borderRadius: borderRadius);

    late final Widget button;
    switch (variant) {
      case 'text':
        button = TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            foregroundColor: resolvedForeground,
            padding: padding ?? defaultPadding,
            minimumSize: minimumSize,
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
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: resolvedForeground,
            padding: padding ?? defaultPadding,
            minimumSize: minimumSize,
            shape: shape,
            side: BorderSide(
              color: textColor ?? theme?.primaryColor ?? const Color(0xFF1D4ED8),
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
      case 'filled':
      case 'elevated':
      default:
        button = FilledButton(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: resolvedBackground,
            foregroundColor: resolvedForeground,
            padding: padding ?? defaultPadding,
            minimumSize: minimumSize,
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
