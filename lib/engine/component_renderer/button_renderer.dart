import 'package:flutter/widgets.dart';
import 'package:sooq_merchant/engine/component_renderer/component_renderer.dart';
import '../../config/component_config.dart';
import '../../core/widgets/primary_button.dart';

class ButtonRenderer implements ComponentRenderer {
  @override
  Widget render(ComponentConfig config) {
    return PrimaryButton(label: config.properties['label'], onPressed: () {});
  }
}
