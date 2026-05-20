// Not rich spans — HTML strip + entity decode only.
import 'package:flutter/material.dart';

import '../../../config/component_config.dart';
import '../../component_renderer/component_renderer.dart';
import '../parsers/data_context_path.dart';
import '../parsers/property_parsers.dart';

class RichTextRenderer implements ComponentRenderer {
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
    var text = value.replaceAll(RegExp(r'<[^>]*>'), '');
    text = text.replaceAll('&nbsp;', ' ');
    text = text.replaceAll('&amp;', '&');
    text = text.replaceAll('&lt;', '<');
    text = text.replaceAll('&gt;', '>');
    text = text.replaceAll('&quot;', '"');
    text = text.replaceAll('&#39;', "'");
    return text;
  }
}
