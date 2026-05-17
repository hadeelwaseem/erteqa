import 'package:flutter/material.dart';

import '../../../config/component_config.dart';

import '../../component_renderer/component_renderer.dart';
import '../parsers/data_context_path.dart';
import '../parsers/property_parsers.dart';

class TextRenderer implements ComponentRenderer {
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
    final fontSize =
        (config.properties['fontSize'] as num?)?.toDouble() ?? 16.0;
    final fontWeight = PropertyParsers.parseFontWeight(
      config.properties['fontWeight'] as String?,
    );
    final color = PropertyParsers.parseColor(
      config.properties['color'] as String?,
    );
    final textAlign = PropertyParsers.parseTextAlign(
      config.properties['textAlign'] as String?,
    );

    return Text(
      value,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        decoration: TextDecoration.none,
      ),
      textAlign: textAlign,
    );
  }

}
