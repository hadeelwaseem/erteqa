import 'package:flutter/widgets.dart';
import '../../config/screen_config.dart';
import '../component_renderer/component_renderer.dart';

class ScreenRenderer {
  final Map<String, ComponentRenderer> renderers;

  ScreenRenderer(this.renderers);

  Widget render(ScreenConfig config, {Map<String, dynamic>? dataContext}) {
    final componentWidgets = <Widget>[];

    for (var entry in config.components.asMap().entries) {
      final index = entry.key;
      final component = entry.value;
      final renderer = renderers[component.type.name];

      if (renderer == null) {
        continue;
      }

      // Add spacing between components (except for the first one)
      if (index > 0) {
        componentWidgets.add(const SizedBox(height: 20));
      }

      componentWidgets.add(
        renderer.render(component, dataContext: dataContext),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: componentWidgets,
    );
  }
}
