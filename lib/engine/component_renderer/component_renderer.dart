import 'package:flutter/widgets.dart';
import '../../config/component_config.dart';

abstract class ComponentRenderer {
  Widget render(ComponentConfig config, {Map<String, dynamic>? dataContext});
}
