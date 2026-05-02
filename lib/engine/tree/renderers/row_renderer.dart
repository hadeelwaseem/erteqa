import 'package:flutter/widgets.dart';

import '../../../config/component_config.dart';
import '../../../core/utils/app_logger.dart';

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

    final resolvedMainAxisAlignment = mainAxisAlignment;
    final resolvedCrossAxisAlignment = crossAxisAlignment;
    final path = dataContext?['_enginePath'] as String? ?? 'unknown';

    return LayoutBuilder(
      builder: (context, constraints) {
        final isUnboundedHeight = !constraints.hasBoundedHeight;
        final safeCrossAxisAlignment =
            isUnboundedHeight &&
                resolvedCrossAxisAlignment == CrossAxisAlignment.stretch
            ? CrossAxisAlignment.center
            : resolvedCrossAxisAlignment;

        if (isUnboundedHeight &&
            resolvedCrossAxisAlignment == CrossAxisAlignment.stretch) {
          AppLogger.debug(
            '[RowRenderer] unbounded height at $path; '
            'fallback stretch -> center',
          );
        }

        return Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: resolvedMainAxisAlignment,
          crossAxisAlignment: safeCrossAxisAlignment,
          children: childWidgets,
        );
      },
    );
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
