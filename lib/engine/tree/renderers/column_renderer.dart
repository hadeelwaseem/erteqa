import 'package:flutter/widgets.dart';

import '../../../config/component_config.dart';
import '../../../core/enums/generic_component_type.dart';

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
    final wantsFlex = mainAxisSize == MainAxisSize.max &&
        children.any(_isExpandContainer);
    final padding = PropertyParsers.parseEdgeInsetsDirectional(
      config.properties['padding'],
    );

    Widget buildColumn({required bool useExpanded}) {
      final built = <Widget>[
        for (final c in children)
          _wrapColumnChild(
            buildChild(c),
            config: c,
            useExpanded: useExpanded,
          ),
      ];
      final childWidgets = _withGap(built, gap);
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

    if (!wantsFlex) {
      return buildColumn(useExpanded: false);
    }

    // Expanded requires a bounded max height. When bounded, clamp this column to the
    // viewport slot and flex the expand child; otherwise skip flex (scroll parents).
    return LayoutBuilder(
      builder: (context, constraints) {
        if (!constraints.maxHeight.isFinite) {
          return buildColumn(useExpanded: false);
        }
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : double.infinity;
        return SizedBox(
          width: width,
          height: constraints.maxHeight,
          child: buildColumn(useExpanded: true),
        );
      },
    );
  }

  static bool _isExpandContainer(ComponentConfig config) {
    return config.type == GenericComponentType.container &&
        config.properties['expand'] == true;
  }

  static Widget _wrapColumnChild(
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
        if (i > 0) SizedBox(height: gap),
        children[i],
      ],
    ];
  }
}
