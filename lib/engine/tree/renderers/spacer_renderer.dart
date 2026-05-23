import 'package:flutter/widgets.dart';

import '../../../config/component_config.dart';
import '../../component_renderer/component_renderer.dart';
import '../parsers/property_parsers.dart';

/// Fixed spacing per flex unit when [Spacer] cannot be used safely.
const double kSpacerFlexUnit = 16;

/// Renders a Spacer component with flexible spacing.
///
/// JSON Properties:
/// - `flex` (number, optional): Flex factor for the spacer. Default: 1.
/// - `width` / `height` (number, optional): Fixed size; bypasses flex.
///
/// Uses [Spacer] only inside a [Row] or [Column] with a valid flex contract.
/// Otherwise renders a fixed [SizedBox] to avoid overflow.
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

    return _SafeSpacer(flex: flex);
  }
}

class _SafeSpacer extends StatelessWidget {
  const _SafeSpacer({required this.flex});

  final int flex;

  @override
  Widget build(BuildContext context) {
    if (_shouldUseSpacer(context)) {
      return Spacer(flex: flex);
    }

    final size = kSpacerFlexUnit * flex;
    return _fallbackAxis(context) == Axis.horizontal
        ? SizedBox(width: size)
        : SizedBox(height: size);
  }

  static bool _shouldUseSpacer(BuildContext context) {
    final row = context.findAncestorWidgetOfExactType<Row>();
    if (row != null) {
      return true;
    }

    final column = context.findAncestorWidgetOfExactType<Column>();
    if (column == null) {
      return false;
    }
    if (column.mainAxisSize == MainAxisSize.min) {
      return false;
    }
    if (context.findAncestorWidgetOfExactType<SingleChildScrollView>() !=
        null) {
      return false;
    }
    if (context.findAncestorWidgetOfExactType<Scrollable>() != null) {
      return false;
    }
    return true;
  }

  static Axis _fallbackAxis(BuildContext context) {
    if (context.findAncestorWidgetOfExactType<Row>() != null) {
      return Axis.horizontal;
    }
    return Axis.vertical;
  }
}
