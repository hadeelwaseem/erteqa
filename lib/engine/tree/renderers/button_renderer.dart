import 'package:flutter/material.dart';

import '../../../config/component_config.dart';
import '../../component_renderer/component_renderer.dart';
import '../../theme/engine_theme.dart';
import '../parsers/property_parsers.dart';
import 'button_label_row.dart';

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
    final fullWidth = PropertyParsers.parseBool(
      config.properties['fullWidth'],
      defaultValue: false,
    );
    final enabled = PropertyParsers.parseBool(
      config.properties['enabled'],
      defaultValue: true,
    );
    final onPressed = enabled ? onTap : null;
    final labelStyle = _buildLabelStyle(
      textColor: textColor,
      foregroundColor: foregroundColor,
      fontSize: PropertyParsers.parseDouble(config.properties['fontSize']),
      fontWeight: PropertyParsers.parseFontWeight(
        config.properties['fontWeight'] as String?,
      ),
      letterSpacing: PropertyParsers.parseDouble(
        config.properties['letterSpacing'],
      ),
    );

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
    final baseMinimumSize = buttonMd != null
        ? Size(0, buttonMd.height)
        : const Size(64, 48);
    final minimumSize = fullWidth
        ? Size(double.infinity, baseMinimumSize.height)
        : maxWidth != null && maxWidth > 0
            ? Size(maxWidth, baseMinimumSize.height)
            : baseMinimumSize;

    final shape = RoundedRectangleBorder(borderRadius: borderRadius);
    final iconName = config.properties['icon'] as String?;
    final iconPosition =
        config.properties['iconPosition'] as String? ?? 'trailing';
    final iconSize = PropertyParsers.parseDouble(config.properties['iconSize']);
    final iconGap = PropertyParsers.parseDouble(config.properties['iconGap']);
    final buttonChild = ButtonLabelRow.build(
      label: label,
      labelStyle: labelStyle,
      iconName: iconName,
      iconPosition: iconPosition,
      iconSize: iconSize,
      iconGap: iconGap,
      iconColor: resolvedForeground,
    );

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
          child: buttonChild,
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
          child: buttonChild,
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
          child: buttonChild,
        );
    }

    Widget wrapped = button;
    if (fullWidth) {
      wrapped = SizedBox(width: double.infinity, child: wrapped);
    } else if (maxWidth != null && maxWidth > 0) {
      wrapped = SizedBox(width: maxWidth, child: wrapped);
    }

    if (alignment != null) {
      wrapped = Align(alignment: alignment, child: wrapped);
    }

    return Semantics(
      button: true,
      enabled: enabled,
      label: label.isNotEmpty ? label : null,
      child: wrapped,
    );
  }

  TextStyle? _buildLabelStyle({
    Color? textColor,
    Color? foregroundColor,
    double? fontSize,
    FontWeight? fontWeight,
    double? letterSpacing,
  }) {
    final hasStyle = textColor != null ||
        foregroundColor != null ||
        fontSize != null ||
        fontWeight != null ||
        letterSpacing != null;
    if (!hasStyle) return null;
    return TextStyle(
      color: foregroundColor ?? textColor,
      fontSize: fontSize,
      fontWeight: fontWeight,
      letterSpacing: letterSpacing,
    );
  }
}
