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

    return Text(_stripHtml(value), style: TextStyle(color: color));
  }

  String _stripHtml(String value) {
    return value.replaceAll(RegExp(r'<[^>]*>'), '');
  }
}
