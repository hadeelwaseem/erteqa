import 'package:flutter/material.dart';

import '../parsers/property_parsers.dart';

/// Shared label + optional icon row for [ButtonRenderer] and [ContactButtonRenderer].
class ButtonLabelRow {
  ButtonLabelRow._();

  static const double defaultIconSize = 18;
  static const double defaultIconGap = 6;

  /// Builds centered label text, or label + icon in a [Row].
  static Widget build({
    required String label,
    TextStyle? labelStyle,
    String? iconName,
    String iconPosition = 'trailing',
    double? iconSize,
    double? iconGap,
    Color? iconColor,
  }) {
    final trimmedIcon = iconName?.trim() ?? '';
    if (trimmedIcon.isEmpty) {
      return Text(label, style: labelStyle);
    }

    final size = iconSize ?? defaultIconSize;
    final gap = iconGap ?? defaultIconGap;
    final iconWidget = Icon(
      PropertyParsers.parseIconData(trimmedIcon),
      size: size,
      color: iconColor ?? labelStyle?.color,
    );
    final labelWidget = Text(label, style: labelStyle);
    final leading = iconPosition.toLowerCase() == 'leading';

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: leading
          ? [iconWidget, SizedBox(width: gap), labelWidget]
          : [labelWidget, SizedBox(width: gap), iconWidget],
    );
  }
}
