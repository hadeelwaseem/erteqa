import 'package:flutter/material.dart';
import 'package:sooq_merchant/engine/component_renderer/component_renderer.dart';
import 'package:sooq_merchant/config/component_config.dart';
import 'package:sooq_merchant/config/models/app_theme_model.dart';
import 'package:sooq_merchant/core/widgets/top_bar.dart';

class TopBarRenderer implements ComponentRenderer {
  @override
  Widget render(ComponentConfig config, {Map<String, dynamic>? dataContext}) {
    final storeName =
        config.properties['storeName'] as String? ?? 'My Store';
    final showCustomizeButton =
        config.properties['showCustomizeButton'] as bool? ?? true;
    final showSearch = config.properties['showSearch'] as bool? ?? true;

    AppThemeModel? colors;
    if (dataContext != null && dataContext.containsKey('appTheme')) {
      colors = dataContext['appTheme'] as AppThemeModel?;
    }

    return TopBar(
      storeName: storeName,
      showSearch: showSearch,
      showCustomizeButton: showCustomizeButton,
      colors: colors,
    );
  }
}
