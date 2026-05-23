import 'package:flutter/material.dart';

import '../../../config/component_config.dart';

import '../../component_renderer/component_renderer.dart';
import '../../theme/engine_theme.dart';
import '../parsers/property_parsers.dart';

class CardRenderer implements ComponentRenderer {
  @override
  Widget render(
    ComponentConfig config, {
    required ComponentWidgetBuilder buildChild,
    Map<String, dynamic>? dataContext,
  }) {
    final theme = EngineTheme.fromDataContext(dataContext);
    final elevation =
        (config.properties['elevation'] as num?)?.toDouble() ?? 0.0;
    final borderRadius = PropertyParsers.parseBorderRadius(
          config.properties['borderRadius'],
        ) ??
        BorderRadius.circular(theme?.radiusMd ?? 10);
    final color = PropertyParsers.parseColor(
          config.properties['color'] as String?,
        ) ??
        theme?.surfaceColor ??
        Colors.white;
    final margin = PropertyParsers.parseEdgeInsets(
      config.properties['margin'],
    );
    final child = config.child != null ? buildChild(config.child!) : null;

    Widget card = Card(
      clipBehavior: Clip.antiAlias,
      elevation: elevation,
      color: color,
      shape: RoundedRectangleBorder(borderRadius: borderRadius),
      child: child,
    );

    if (margin != null) {
      card = Padding(padding: margin, child: card);
    }

    return card;
  }
}
