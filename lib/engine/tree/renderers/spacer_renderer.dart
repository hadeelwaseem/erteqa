import 'package:flutter/widgets.dart';

import '../../../config/component_config.dart';
import '../../component_renderer/component_renderer.dart';
import '../parsers/property_parsers.dart';

/// Renders a Spacer component with flexible spacing.
///
/// JSON Properties:
/// - `flex` (number, optional): Flex factor for the spacer. Default: 1.
///
/// Example JSON:
/// ```json
/// {
///   "type": "spacer",
///   "flex": 5
/// }
/// ```
class SpacerRenderer implements ComponentRenderer {
  @override
  Widget render(
    ComponentConfig config, {
    required ComponentWidgetBuilder buildChild,
    Map<String, dynamic>? dataContext,
  }) {
    final width = PropertyParsers.parseDouble(config.properties['width']);
    final height = PropertyParsers.parseDouble(config.properties['height']);
    if (width != null || height != null) {
      return SizedBox(width: width, height: height);
    }

    final flex = (config.properties['flex'] as num?)?.toInt() ?? 1;

    return Spacer(flex: flex);
  }
}
