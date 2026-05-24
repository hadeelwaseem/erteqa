import 'package:flutter/widgets.dart';

import '../../../config/component_config.dart';
import '../../../core/enums/generic_component_type.dart';
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
    final mainAxisSize = PropertyParsers.parseMainAxisSize(
      config.properties['mainAxisSize'] as String?,
      defaultValue: MainAxisSize.max,
    );
    final textDirection = PropertyParsers.parseTextDirection(
      config.properties['textDirection'] as String?,
    );
    final children = config.layoutChildren;
    final gap = PropertyParsers.parseDouble(config.properties['gap']) ?? 0;
    final wantsFlex = children.any(_isExpandContainer);
    final childWidgets = _withGap(
      children
          .map(
            (c) => _wrapRowChild(
              buildChild(c),
              config: c,
              useExpanded: wantsFlex,
            ),
          )
          .toList(),
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
            ? CrossAxisAlignment.start
            : resolvedCrossAxisAlignment;

        if (isUnboundedHeight &&
            resolvedCrossAxisAlignment == CrossAxisAlignment.stretch) {
          AppLogger.debug(
            '[RowRenderer] unbounded height at $path; '
            'fallback stretch -> start',
          );
        }

        final row = Row(
          mainAxisSize: mainAxisSize,
          mainAxisAlignment: resolvedMainAxisAlignment,
          crossAxisAlignment: safeCrossAxisAlignment,
          textDirection: textDirection,
          children: childWidgets,
        );

        if (constraints.hasBoundedWidth) {
          return SizedBox(width: double.infinity, child: row);
        }
        return row;
      },
    );
  }

  static bool _isExpandContainer(ComponentConfig config) {
    return config.type == GenericComponentType.container &&
        config.properties['expand'] == true;
  }

  static Widget _wrapRowChild(
    Widget child, {
    required ComponentConfig config,
    required bool useExpanded,
  }) {
    if (useExpanded && _isExpandContainer(config)) {
      return Expanded(child: child);
    }
    return child;
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
