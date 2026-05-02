import 'package:flutter/widgets.dart';

import '../../../config/component_config.dart';

import '../../component_renderer/component_renderer.dart';
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
    final gap = PropertyParsers.parseDouble(config.properties['gap']) ?? 0;
    final childWidgets = _withGap(
      children.map((c) => buildChild(c)).toList(),
      gap,
    );

    final row = Row(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      children: childWidgets,
    );

    // IntrinsicHeight ensures Row gets bounded height when parent gives unbounded
    // (e.g. Column child). Prevents "BoxConstraints forces an infinite height"
    // when crossAxisAlignment is stretch.
    return IntrinsicHeight(child: row);
  }

  List<Widget> _withGap(List<Widget> children, double gap) {
    if (gap <= 0 || children.length < 2) return children;
    return [
      for (var i = 0; i < children.length; i++) ...[
        if (i > 0) SizedBox(width: gap),
        children[i],
      ],
    ];
  }
}
