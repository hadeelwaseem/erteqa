import 'package:flutter/widgets.dart';
import 'package:sooq_merchant/engine/component_renderer/component_renderer.dart';
import '../../config/component_config.dart';
import '../../core/widgets/primary_button.dart';
import '../../config/models/app_theme_model.dart';

class ButtonRenderer implements ComponentRenderer {
  @override
  Widget render(ComponentConfig config, {Map<String, dynamic>? dataContext}) {
    AppThemeModel? colors;
    if (dataContext != null && dataContext.containsKey('appTheme')) {
      colors = dataContext['appTheme'] as AppThemeModel?;
    }

    return PrimaryButton(
      label: config.properties['label'] as String? ?? '',
      onPressed: () {},
      backgroundColor: colors?.button,
    );
  }
}
