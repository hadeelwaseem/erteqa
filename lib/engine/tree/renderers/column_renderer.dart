import 'package:flutter/widgets.dart';

import '../../../config/genericConfig/component_config.dart';

import 'component_renderer.dart';
import '../parsers/property_parsers.dart';

class ColumnRenderer implements ComponentRenderer {
  @override
  Widget render(
    ComponentConfig config, {
    required ComponentWidgetBuilder buildChild,
    Map<String, dynamic>? dataContext,
  }) {
    final mainAxisAlignment = PropertyParsers.parseMainAxisAlignment(
      config.properties['mainAxisAlignment'] as String?,
    );
    final crossAxisAlignment = PropertyParsers.parseCrossAxisAlignment(
      config.properties['crossAxisAlignment'] as String?,
    );
    final children = config.children ?? [];
    final childWidgets = children.map((c) => buildChild(c)).toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      children: childWidgets,
    );
  }
}
