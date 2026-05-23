import 'package:flutter/material.dart';

import '../../../config/component_config.dart';
import '../../component_renderer/component_renderer.dart';
import '../../engine_page_chrome.dart';
import '../parsers/property_parsers.dart';

/// Registers a Material [Drawer] for the current page in [dataContext].
///
/// Returns [SizedBox.shrink] so the node does not affect layout; [ScreenRenderer]
/// wraps the page in an inner [Scaffold] with [Scaffold.drawer] / [endDrawer].
class AppDrawerRenderer implements ComponentRenderer {
  @override
  Widget render(
    ComponentConfig config, {
    required ComponentWidgetBuilder buildChild,
    Map<String, dynamic>? dataContext,
  }) {
    final properties = config.properties;
    final drawerEdge = (properties['drawerEdge'] as String?)?.toLowerCase() ?? 'start';
    final width = PropertyParsers.parseDouble(properties['width']) ?? 280.0;
    final backgroundColor = PropertyParsers.parseColor(
      properties['backgroundColor'] as String?,
    );

    final child = config.child;
    final drawerChild = child != null
        ? buildChild(child)
        : const SizedBox.shrink();

    final registry = _registryFrom(dataContext);
    if (registry != null) {
      registry
        ..drawer = Drawer(
          width: width,
          backgroundColor: backgroundColor,
          child: drawerChild,
        )
        ..drawerEdge = drawerEdge;
    }

    return const SizedBox.shrink();
  }

  EnginePageChromeRegistry? _registryFrom(Map<String, dynamic>? dataContext) {
    final existing = dataContext?[EnginePageChromeRegistry.contextKey];
    return existing is EnginePageChromeRegistry ? existing : null;
  }
}
