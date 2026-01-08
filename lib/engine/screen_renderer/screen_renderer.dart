import 'package:flutter/widgets.dart';
import '../../config/screen_config.dart';
import '../component_renderer/component_renderer.dart';

class ScreenRenderer {
  final Map<String, ComponentRenderer> renderers;

  ScreenRenderer(this.renderers);

  Widget render(ScreenConfig config) {
    return Column(
      children: config.components.map((component) {
        final renderer = renderers[component.type.name];
        return renderer!.render(component);
      }).toList(),
    );
  }
}
