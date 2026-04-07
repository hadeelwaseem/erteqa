import 'package:flutter/material.dart';

import '../../../config/component_config.dart';

import '../../component_renderer/component_renderer.dart';
import '../parsers/property_parsers.dart';

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

    return Scaffold(
      backgroundColor: backgroundColor,
      body: child != null
          ? SingleChildScrollView(child: child)
          : const SizedBox.shrink(),
    );
  }
}
