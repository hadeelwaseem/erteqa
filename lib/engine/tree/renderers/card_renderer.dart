import 'package:flutter/material.dart';

import '../../../config/component_config.dart';

import '../../component_renderer/component_renderer.dart';
import '../../theme/engine_theme.dart';
import '../../theme/shadow_parser.dart';
import '../parsers/property_parsers.dart';

class CardRenderer implements ComponentRenderer {
  @override
  Widget render(
    ComponentConfig config, {
    required ComponentWidgetBuilder buildChild,
    Map<String, dynamic>? dataContext,
  }) {
    final theme = EngineTheme.fromDataContext(dataContext);
    final elevation = _resolveElevation(config.properties, theme);
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

    // M3 surface tint reads as flat tone on #F1F5F9; explicit shadow reads clearer.
    Widget card = Card(
      clipBehavior: Clip.antiAlias,
      elevation: elevation,
      shadowColor: const Color(0x59000000),
      surfaceTintColor: Colors.transparent,
      color: color,
      shape: RoundedRectangleBorder(borderRadius: borderRadius),
      child: child,
    );

    if (margin != null) {
      card = Padding(padding: margin, child: card);
    }

    return card;
  }

  static double _resolveElevation(
    Map<String, dynamic> properties,
    EngineTheme? theme,
  ) {
    if (properties.containsKey('elevation')) {
      return (properties['elevation'] as num?)?.toDouble() ?? 0.0;
    }
    final preset = theme?.defaultShadowPreset('card');
    if (preset != null) {
      return ShadowParser.materialElevationForPreset(preset) ?? 0.0;
    }
    return 0.0;
  }
}
