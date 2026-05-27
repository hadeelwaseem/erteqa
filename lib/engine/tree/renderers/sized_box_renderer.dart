import 'package:flutter/widgets.dart';

import '../../../config/component_config.dart';
import '../../component_renderer/component_renderer.dart';
import '../parsers/property_parsers.dart';

/// Fixed-size layout gap — maps to Flutter [SizedBox].
///
/// JSON props (all optional):
/// - `width` — horizontal extent in logical pixels
/// - `height` — vertical extent in logical pixels
///
/// Optional `child` constrains the child to the given width/height.
/// With no child and at least one dimension set, renders empty spacing.
class SizedBoxRenderer implements ComponentRenderer {
  @override
  Widget render(
    ComponentConfig config, {
    required ComponentWidgetBuilder buildChild,
    Map<String, dynamic>? dataContext,
  }) {
    final width = PropertyParsers.parseDouble(config.properties['width']);
    final height = PropertyParsers.parseDouble(config.properties['height']);
    final child = config.child != null ? buildChild(config.child!) : null;

    return SizedBox(width: width, height: height, child: child);
  }
}
