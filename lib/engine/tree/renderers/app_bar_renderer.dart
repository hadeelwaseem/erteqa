import 'package:flutter/material.dart';

import '../../../config/component_config.dart';
import '../../component_renderer/component_renderer.dart';
import '../parsers/property_parsers.dart';

/// Renders an app bar row with optional back button.
///
/// JSON props:
/// - `title` (string) — bar title text
/// - `color` (hex string) — foreground/text color
/// - `backgroundColor` / `color` from style — background color
///
/// Back button appears automatically when [Navigator.canPop] is true.
class AppBarRenderer implements ComponentRenderer {
  @override
  Widget render(
    ComponentConfig config, {
    required ComponentWidgetBuilder buildChild,
    Map<String, dynamic>? dataContext,
  }) {
    final title = config.properties['title'] as String? ?? '';
    final backgroundColorHex =
        config.properties['backgroundColor'] as String? ??
        config.properties['color'] as String?;
    final backgroundColor = PropertyParsers.parseColor(backgroundColorHex);

    return Builder(
      builder: (context) {
        final canPop = Navigator.canPop(context);

        return Material(
          color: backgroundColor ?? Colors.white,
          elevation: 1,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Row(
                children: [
                  if (canPop)
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  if (!canPop) const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 18,
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
