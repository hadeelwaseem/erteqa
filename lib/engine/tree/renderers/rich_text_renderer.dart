import 'package:flutter/material.dart';

import '../../../config/component_config.dart';
import '../../component_renderer/component_renderer.dart';
import '../parsers/property_parsers.dart';

class RichTextRenderer implements ComponentRenderer {
  @override
  Widget render(
    ComponentConfig config, {
    required ComponentWidgetBuilder buildChild,
    Map<String, dynamic>? dataContext,
  }) {
    final value = config.properties['value'] as String? ?? '';
    final color = PropertyParsers.parseColor(
      config.properties['color'] as String?,
    );
    final fontSize = PropertyParsers.parseDouble(config.properties['fontSize']);
    final fontWeight = PropertyParsers.parseFontWeight(
      config.properties['fontWeight'] as String?,
    );
    final textAlign = PropertyParsers.parseTextAlign(
      config.properties['textAlign'] as String?,
    );
    final height = PropertyParsers.parseDouble(config.properties['height']);

    return Text(
      _stripHtml(value),
      textAlign: textAlign,
      style: TextStyle(
        color: color,
        decoration: TextDecoration.none,
        fontSize: fontSize,
        fontWeight: fontWeight,
        height: height,
      ),
    );
  }

  String _stripHtml(String value) {
    return value.replaceAll(RegExp(r'<[^>]*>'), '');
  }
}
