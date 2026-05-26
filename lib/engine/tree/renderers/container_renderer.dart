import 'package:flutter/widgets.dart';

import '../../../config/component_config.dart';
import '../../component_renderer/component_renderer.dart';
import '../../request_ui_state.dart';
import '../../skeleton/request_bound_skeleton.dart';
import '../../skeleton/skeleton_item_factory.dart';
import '../../theme/engine_theme.dart';
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
/// - `expand` (bool) — fill parent when width/height omitted
/// - `expandAxis` (string, optional) — `horizontal` | `vertical` | `both` (default
///   `both`). Use `horizontal` for row flex children (search bar text) so height
///   stays intrinsic.
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

    final requestKey = resolveRequestKey(config.properties);
    if (requestKey != null) {
      final requestMap = requestMapForKey(dataContext, requestKey);
      final phase = resolveRequestBoundListPhase(
        requestKey: requestKey,
        dataContext: dataContext,
        itemsEmpty: isRequestPayloadEmpty(requestMap),
      );

      if (phase == RequestBoundListPhase.loading) {
        if (config.child != null) {
          final ctx = SkeletonItemFactory.detailRequestContext(
            dataContext,
            requestKey,
          );
          final childConfig = SkeletonItemFactory.withContextOverride(
            config.child!,
            ctx,
          );
          var builtChild = buildChild(childConfig);
          builtChild = _applyExpandIfNeeded(
            builtChild,
            config: config,
            width: width,
            height: height,
          );
          final wrapped = RequestBoundSkeleton.wrap(
            child: builtChild,
            dataContext: dataContext,
          );
          return _buildShell(
            width: width,
            height: height,
            padding: padding,
            margin: margin,
            color: color,
            borderRadius: borderRadius,
            shadow: shadow,
            border: border,
            child: wrapped,
          );
        }
        return buildRequestPhasePlaceholder(phase: phase, message: '');
      }

      if (phase == RequestBoundListPhase.error ||
          phase == RequestBoundListPhase.empty) {
        final message = switch (phase) {
          RequestBoundListPhase.error => resolveDisplayMessage(
            prop: config.properties['errorMessage'] as String?,
            requestMap: requestMap,
            fallback: kDefaultErrorMessage,
          ),
          RequestBoundListPhase.empty => resolveDisplayMessage(
            prop: config.properties['emptyMessage'] as String?,
            requestMap: requestMap,
            fallback: kDefaultEmptyMessage,
          ),
          _ => '',
        };
        return buildRequestPhasePlaceholder(phase: phase, message: message);
      }
    }

    Widget? child = config.child != null ? buildChild(config.child!) : null;
    if (child != null) {
      child = _applyExpandIfNeeded(
        child,
        config: config,
        width: width,
        height: height,
      );
    }

    return _buildShell(
      width: width,
      height: height,
      padding: padding,
      margin: margin,
      color: color,
      borderRadius: borderRadius,
      shadow: shadow,
      border: border,
      child: child,
    );
  }

  static Widget _buildShell({
    required double? width,
    required double? height,
    required EdgeInsetsDirectional? padding,
    required EdgeInsetsDirectional? margin,
    required Color? color,
    required BorderRadius? borderRadius,
    required BoxShadow? shadow,
    required Border? border,
    required Widget? child,
  }) {
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

  static Widget _applyExpandIfNeeded(
    Widget child, {
    required ComponentConfig config,
    required double? width,
    required double? height,
  }) {
    final expand = config.properties['expand'] == true;
    if (!expand || width != null || height != null) {
      return child;
    }
    final expandedChild = child;
    final expandAxis = (config.properties['expandAxis'] as String? ?? 'both')
        .toLowerCase();
    return LayoutBuilder(
      builder: (context, constraints) {
        final canWidth =
            constraints.maxWidth.isFinite && expandAxis != 'vertical';
        final canHeight =
            constraints.maxHeight.isFinite && expandAxis != 'horizontal';

        if (canWidth && canHeight) {
          return SizedBox(
            width: double.infinity,
            height: constraints.maxHeight,
            child: expandedChild,
          );
        }
        if (canWidth) {
          return SizedBox(
            width: double.infinity,
            child: expandedChild,
          );
        }
        if (canHeight) {
          return SizedBox(
            height: constraints.maxHeight,
            width: constraints.maxWidth.isFinite
                ? constraints.maxWidth
                : double.infinity,
            child: expandedChild,
          );
        }
        final expandHeight = _expandHeight(context, constraints);
        return SizedBox(
          width: double.infinity,
          height: expandHeight,
          child: expandedChild,
        );
      },
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
