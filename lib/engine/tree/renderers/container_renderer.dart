import 'package:flutter/widgets.dart';

import '../../../config/component_config.dart';
import '../../theme/engine_theme.dart';

import '../../component_renderer/component_renderer.dart';
import '../parsers/property_parsers.dart';

/// Renders a container node with optional background, padding, margin,
/// border-radius, shadow, and border.
///
/// JSON props (all optional):
/// - `color` — background (#hex)
/// - `padding` — numeric or {top,right,bottom,left}
/// - `margin` — {top,right,bottom,left}
/// - `borderRadius` — numeric
/// - `width` / `height` — numeric px
/// - `expand` (bool) — fill parent width/height when width/height omitted; inside
///   scroll views uses [BoxConstraints.minHeight] or viewport (not infinite expand)
/// - `shadow` — "sm" | "md" | "lg" | "xl" | "none"
/// - `border` — {width, color}
class ContainerRenderer implements ComponentRenderer {
  @override
  Widget render(
    ComponentConfig config, {
    required ComponentWidgetBuilder buildChild,
    Map<String, dynamic>? dataContext,
  }) {
    final padding = PropertyParsers.parseEdgeInsetsDirectional(
      config.properties['padding'],
    );
    final margin = PropertyParsers.parseEdgeInsetsDirectional(
      config.properties['margin'],
    );
    final color = PropertyParsers.parseColor(
      config.properties['color'] as String?,
    );
    final borderRadius = PropertyParsers.parseBorderRadius(
      config.properties['borderRadius'],
    );
    final width = PropertyParsers.parseDouble(config.properties['width']);
    final height = PropertyParsers.parseDouble(config.properties['height']);
    final shadow = _parseShadow(config.properties['shadow']);
    final border = _parseBorder(config.properties['border'], dataContext);
    Widget? child = config.child != null ? buildChild(config.child!) : null;
    final expand = config.properties['expand'] == true;
    if (expand && child != null && width == null && height == null) {
      final expandedChild = child;
      child = LayoutBuilder(
        builder: (context, constraints) {
          // Inside Expanded / bounded column: fill the slot, do not force full viewport.
          if (constraints.maxHeight.isFinite) {
            return SizedBox(
              width: double.infinity,
              height: constraints.maxHeight,
              child: expandedChild,
            );
          }
          final height = _expandHeight(context, constraints);
          return SizedBox(
            width: double.infinity,
            height: height,
            child: expandedChild,
          );
        },
      );
    }

    final hasDecoration =
        color != null ||
        borderRadius != null ||
        shadow != null ||
        border != null;

    return Container(
      width: width,
      height: height,
      padding: padding,
      margin: margin,
      decoration: hasDecoration
          ? BoxDecoration(
              color: color,
              borderRadius: borderRadius,
              boxShadow: shadow != null ? [shadow] : null,
              border: border,
            )
          : null,
      child: child,
    );
  }

  /// Height for [expand]. Prefer finite parent constraints (e.g. [Expanded] or
  /// [Column] with [MainAxisSize.max]). Falls back to scroll min-height or viewport.
  static double _expandHeight(BuildContext context, BoxConstraints constraints) {
    if (constraints.maxHeight.isFinite) {
      return constraints.maxHeight;
    }
    if (constraints.minHeight > 0 && constraints.minHeight.isFinite) {
      return constraints.minHeight;
    }
    final media = MediaQuery.sizeOf(context);
    return media.height.clamp(0.0, double.infinity);
  }

  BoxShadow? _parseShadow(dynamic v) {
    if (v == null || v == 'none') return null;
    switch (v) {
      case 'sm':
        return const BoxShadow(
          color: Color(0x1A000000),
          blurRadius: 4,
          offset: Offset(0, 1),
        );
      case 'md':
        return const BoxShadow(
          color: Color(0x26000000),
          blurRadius: 8,
          offset: Offset(0, 2),
        );
      case 'lg':
        return const BoxShadow(
          color: Color(0x33000000),
          blurRadius: 16,
          offset: Offset(0, 4),
        );
      case 'xl':
        return const BoxShadow(
          color: Color(0x40000000),
          blurRadius: 24,
          offset: Offset(0, 8),
        );
      default:
        return null;
    }
  }

  Border? _parseBorder(dynamic v, Map<String, dynamic>? dataContext) {
    if (v is! Map) return null;
    final width = (v['width'] as num?)?.toDouble() ?? 1.0;
    final theme = EngineTheme.fromDataContext(dataContext);
    final color =
        PropertyParsers.parseColor(v['color'] as String?) ??
        theme?.inputBorderColor ??
        const Color(0xFFE2E8F0);
    return Border.all(width: width, color: color);
  }
}
