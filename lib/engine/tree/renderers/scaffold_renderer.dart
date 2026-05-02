import 'package:flutter/material.dart';

import '../../../config/component_config.dart';

import '../../component_renderer/component_renderer.dart';
import '../parsers/property_parsers.dart';

/// Renders the top-level page scaffold as a scrollable color-wrapped container.
///
/// NOTE: Does NOT create a Flutter [Scaffold] widget — the outer Scaffold is
/// provided by [TabShellWidget] (via ShellRoute). Creating a nested Scaffold
/// here would cause double-scaffold issues (duplicate bottom bars, etc.).
///
/// JSON props:
/// - `backgroundColor` (string, hex color) — page background
class ScaffoldRenderer implements ComponentRenderer {
  @override
  Widget render(
    ComponentConfig config, {
    required ComponentWidgetBuilder buildChild,
    Map<String, dynamic>? dataContext,
  }) {
    final backgroundColor = PropertyParsers.parseColor(
      config.properties['backgroundColor'] as String?,
    );
    final child = config.child != null ? buildChild(config.child!) : null;

    return ColoredBox(
      color: backgroundColor ?? const Color(0xFFF8FAFC),
      child: child != null
          ? SingleChildScrollView(child: child)
          : const SizedBox.expand(),
    );
  }
}
