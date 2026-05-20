import 'package:flutter/material.dart';

import '../../../config/component_config.dart';

import '../../component_renderer/component_renderer.dart';
import '../../theme/engine_theme.dart';
import '../parsers/data_context_path.dart';
import '../parsers/property_parsers.dart';

class TextRenderer implements ComponentRenderer {
  static final _leadingDigit = RegExp(r'^\d');

  @override
  Widget render(
    ComponentConfig config, {
    required ComponentWidgetBuilder buildChild,
    Map<String, dynamic>? dataContext,
  }) {
    final valuePath = config.properties['valuePath'] as String?;
    final boundValue = resolveDataContextPath(dataContext, valuePath);
    final value =
        (boundValue?.toString().trim().isNotEmpty ?? false)
        ? boundValue.toString()
        : (config.properties['value'] as String? ?? '');
    final theme = EngineTheme.fromDataContext(dataContext);

    final fontSizeRaw = config.properties['fontSize'];
    final double fontSize;
    if (fontSizeRaw is num) {
      fontSize = fontSizeRaw.toDouble();
    } else if (fontSizeRaw is String &&
        !_leadingDigit.hasMatch(fontSizeRaw.trim())) {
      fontSize = theme?.typographyScale(fontSizeRaw.trim().toLowerCase()) ??
          _typographyScaleForKey(fontSizeRaw.trim().toLowerCase());
    } else {
      final scaleKey =
          (config.properties['typographyScale'] as String?)?.toLowerCase() ??
          'md';
      fontSize =
          theme?.typographyScale(scaleKey) ?? _typographyScaleForKey(scaleKey);
    }

    final fontWeight = PropertyParsers.parseFontWeight(
      config.properties['fontWeight'] as String?,
    );
    final color = PropertyParsers.parseColor(
          config.properties['color'] as String?,
        ) ??
        theme?.textColor;
    final textAlign = PropertyParsers.parseTextAlign(
      config.properties['textAlign'] as String?,
    );
    final maxLines = PropertyParsers.parseInt(config.properties['maxLines']);
    final overflowRaw = config.properties['overflow'] as String?;
    final overflow = PropertyParsers.parseTextOverflow(overflowRaw) ??
        (maxLines != null ? TextOverflow.ellipsis : TextOverflow.clip);
    final fontStyle = PropertyParsers.parseFontStyle(
      config.properties['fontStyle'] as String?,
    );

    return Text(
      value,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        fontStyle: fontStyle,
        decoration: TextDecoration.none,
      ),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }

  static double _typographyScaleForKey(String key) {
    switch (key) {
      case 'xs':
        return 12;
      case 'sm':
        return 13;
      case 'lg':
        return 18;
      case 'xl':
        return 22;
      default:
        return 16;
    }
  }
}
