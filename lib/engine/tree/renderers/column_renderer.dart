import 'package:flutter/widgets.dart';

import '../../../config/component_config.dart';

import '../../component_renderer/component_renderer.dart';
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
    final mainAxisSize = PropertyParsers.parseMainAxisSize(
      config.properties['mainAxisSize'] as String?,
      defaultValue: MainAxisSize.min,
    );
    final textDirection = PropertyParsers.parseTextDirection(
      config.properties['textDirection'] as String?,
    );
    final children = config.children ?? [];
    final gap = PropertyParsers.parseDouble(config.properties['gap']) ?? 0;
    final childWidgets = _withGap(
      children.map((c) => buildChild(c)).toList(),
      gap,
    );

    final padding = PropertyParsers.parseEdgeInsetsDirectional(
      config.properties['padding'],
    );

    Widget column = Column(
      mainAxisSize: mainAxisSize,
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      textDirection: textDirection,
      children: childWidgets,
    );
    if (padding != null) {
      column = Padding(padding: padding, child: column);
    }
    return column;
  }

  List<Widget> _withGap(List<Widget> children, double gap) {
    if (gap <= 0 || children.length < 2) return children;
    return [
      for (var i = 0; i < children.length; i++) ...[
        if (i > 0) SizedBox(height: gap),
        children[i],
      ],
    ];
  }
}
