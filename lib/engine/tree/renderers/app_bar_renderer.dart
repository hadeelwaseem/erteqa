import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../config/component_config.dart';
import '../../component_renderer/component_renderer.dart';
import '../../theme/engine_theme.dart';
import '../parsers/property_parsers.dart';

/// Renders an app bar row with optional back button.
///
/// JSON props:
/// - `title` (string) — bar title text
/// - `backgroundColor` (hex) — bar background
/// - `color` (hex) — legacy background from `style.background` merge
/// - `foregroundColor` / `titleColor` (hex) — title and back icon color
///
/// Back button appears automatically when `context.canPop()` (GoRouter) is true.
class AppBarRenderer implements ComponentRenderer {
  @override
  Widget render(
    ComponentConfig config, {
    required ComponentWidgetBuilder buildChild,
    Map<String, dynamic>? dataContext,
  }) {
    final title = config.properties['title'] as String? ?? '';
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

    return Builder(
      builder: (context) {
        final canPop = context.canPop();

        return Material(
          color: backgroundColor,
          elevation: 1,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Row(
                children: [
                  if (canPop)
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: foregroundColor),
                      onPressed: () => context.pop(),
                      constraints: const BoxConstraints(
                        minWidth: 48,
                        minHeight: 48,
                      ),
                      padding: const EdgeInsets.all(12),
                    ),
                  if (!canPop) const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        color: foregroundColor,
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
