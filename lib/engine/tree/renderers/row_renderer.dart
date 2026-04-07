import 'package:flutter/widgets.dart';

import '../../../config/genericConfig/component_config.dart';

import 'component_renderer.dart';
import '../parsers/property_parsers.dart';

class RowRenderer implements ComponentRenderer {
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

    final row = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      children: childWidgets,
    );

    // IntrinsicHeight ensures Row gets bounded height when parent gives unbounded
    // (e.g. Column child). Prevents "BoxConstraints forces an infinite height"
    // when crossAxisAlignment is stretch.
    return IntrinsicHeight(child: row);
  }
}
