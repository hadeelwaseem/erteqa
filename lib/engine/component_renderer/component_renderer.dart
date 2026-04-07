import 'package:flutter/widgets.dart';

import '../../config/component_config.dart';

typedef ComponentWidgetBuilder = Widget Function(ComponentConfig config);

/// Interface for rendering a component config into a Flutter widget.
/// Receives [buildChild] to recursively build child components.
abstract class ComponentRenderer {
  Widget render(
    ComponentConfig config, {
    required ComponentWidgetBuilder buildChild,
    Map<String, dynamic>? dataContext,
  });
}
