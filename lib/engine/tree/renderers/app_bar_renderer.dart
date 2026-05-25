import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../config/component_config.dart';
import '../../../core/utils/icon_registry.dart';
import '../../actions/action_dispatcher.dart';
import '../../component_renderer/component_renderer.dart';
import '../../theme/engine_theme.dart';
import '../parsers/property_parsers.dart';

/// Renders a top app bar row with optional back, menu, title, and trailing icon.
///
/// JSON props:
/// - `title` (string)
/// - `showMenu` (bool) — menu icon on the visual right; default action `openDrawer`
/// - `menuIcon` (string) — Material icon name, default `menu`
/// - `menuAction` (action map) — defaults to `{ type: openDrawer }`
/// - `trailingIcon` (string) — secondary icon on the visual left (e.g. notifications)
/// - `trailingAction` (action map)
/// - `titleAlign` (string) — `start` (default) | `center` | `end`
///   `start`/`end` follow app text direction (RTL → title on the right by default).
/// - `height` (number) — optional fixed bar height in logical pixels
/// - `elevation` (number) — Material elevation; default `1`
/// - `backgroundColor`, `foregroundColor` / `titleColor` — hex `#RRGGBB`, `#AARRGGBB`, or `transparent`
///
/// Bar layout uses LTR: notifications left, menu and back on the right.
/// Back button shows on the right when [GoRouter] can pop.
class AppBarRenderer implements ComponentRenderer {
  static const _minTapTarget = 48.0;

  @override
  Widget render(
    ComponentConfig config, {
    required ComponentWidgetBuilder buildChild,
    Map<String, dynamic>? dataContext,
  }) {
    final properties = config.properties;
    final title = properties['title'] as String? ?? '';
    final theme = EngineTheme.fromDataContext(dataContext);

    final backgroundColorHex =
        config.properties['backgroundColor'] as String? ??
        config.properties['color'] as String?;
    final backgroundColor = PropertyParsers.parseColor(backgroundColorHex) ??
        theme?.surfaceColor ??
        Colors.white;

    final foregroundHex =
        config.properties['foregroundColor'] as String? ??
        config.properties['titleColor'] as String?;
    final foregroundColor =
        PropertyParsers.parseColor(foregroundHex) ?? theme?.textColor;

    final titleFontSize = theme?.typographyScale('lg') ?? 18.0;
    final showMenu = properties['showMenu'] == true;
    final menuIconName = properties['menuIcon'] as String? ?? 'menu';
    final menuAction = properties['menuAction'] is Map<String, dynamic>
        ? properties['menuAction'] as Map<String, dynamic>
        : const {'type': 'openDrawer'};
    final trailingIconName = properties['trailingIcon'] as String?;
    final trailingAction = properties['trailingAction'] as Map<String, dynamic>?;
    final titleAlignRaw =
        (properties['titleAlign'] as String?)?.toLowerCase() ?? 'start';
    final titleCenter = titleAlignRaw == 'center';
    final titleTextAlign = PropertyParsers.parseTextAlign(titleAlignRaw);
    final barHeight = PropertyParsers.parseDouble(properties['height']);
    final elevation = PropertyParsers.parseDouble(properties['elevation']) ?? 1.0;

    return Builder(
      builder: (context) {
        final statusBarTop = MediaQuery.paddingOf(context).top;
        final ambientDirection = Directionality.of(context);
        final router = GoRouter.of(context);
        final canPop = router.canPop();
        final dispatcher = _resolveDispatcher(dataContext, context);

        Widget leftSlot;
        if (trailingIconName != null && trailingIconName.isNotEmpty) {
          leftSlot = _iconButton(
            icon: IconRegistry.resolve(trailingIconName),
            color: foregroundColor,
            onPressed: trailingAction == null || dispatcher == null
                ? null
                : () => dispatcher.dispatch(
                      trailingAction,
                      dataContext: dataContext,
                    ),
            semanticLabel: 'Action',
          );
        } else {
          leftSlot = const SizedBox(width: _minTapTarget);
        }

        Widget rightSlot;
        if (showMenu && !canPop) {
          rightSlot = _iconButton(
            icon: IconRegistry.resolve(menuIconName),
            color: foregroundColor,
            onPressed: dispatcher == null
                ? null
                : () => dispatcher.dispatch(
                      menuAction,
                      dataContext: dataContext,
                    ),
            semanticLabel: 'Menu',
          );
        } else if (canPop) {
          rightSlot = _iconButton(
            icon: Icons.arrow_forward,
            color: foregroundColor,
            onPressed: () => router.pop(),
            semanticLabel: 'Back',
          );
        } else {
          rightSlot = const SizedBox(width: _minTapTarget);
        }

        final titleStyle = TextStyle(
          color: foregroundColor,
          fontSize: titleFontSize,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        );

        final titleWidget = titleCenter
            ? Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: titleStyle,
              )
            : Align(
                alignment: switch (titleAlignRaw) {
                  'end' => AlignmentDirectional.centerEnd,
                  'center' => Alignment.center,
                  _ => AlignmentDirectional.centerStart,
                },
                child: Text(
                  title,
                  textAlign: titleTextAlign,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: titleStyle,
                ),
              );

        final barRow = Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Row(
              children: [
                leftSlot,
                Expanded(
                  child: Directionality(
                    textDirection: ambientDirection,
                    child: titleWidget,
                  ),
                ),
                rightSlot,
              ],
            ),
          ),
        );

        final barContent = barHeight != null
            ? SizedBox(
                height: barHeight,
                child: Align(
                  alignment: Alignment.center,
                  child: barRow,
                ),
              )
            : barRow;

        return Material(
          color: backgroundColor,
          elevation: elevation,
          shadowColor: elevation > 0 ? null : Colors.transparent,
          surfaceTintColor: Colors.transparent,
          child: Padding(
            padding: EdgeInsets.only(top: statusBarTop),
            child: barContent,
          ),
        );
      },
    );
  }

  Widget _iconButton({
    required IconData icon,
    required Color? color,
    required VoidCallback? onPressed,
    required String semanticLabel,
  }) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: IconButton(
        icon: Icon(icon, color: color),
        onPressed: onPressed,
        constraints: const BoxConstraints(
          minWidth: _minTapTarget,
          minHeight: _minTapTarget,
        ),
        padding: const EdgeInsets.all(12),
      ),
    );
  }

  EngineActionDispatcher? _resolveDispatcher(
    Map<String, dynamic>? dataContext,
    BuildContext context,
  ) {
    if (dataContext != null) {
      final existing = dataContext[EngineActionDispatcher.contextKey];
      if (existing is EngineActionDispatcher) return existing;
    }
    final dispatcher = EngineActionDispatcher(
      context: context,
      dataContext: dataContext,
    );
    dataContext?[EngineActionDispatcher.contextKey] = dispatcher;
    return dispatcher;
  }
}
