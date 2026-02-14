import 'package:flutter/material.dart';
import 'package:sooq_merchant/engine/component_renderer/component_renderer.dart';
import '../../config/component_config.dart';
import '../../core/widgets/text_component.dart';
import '../../config/models/app_theme_model.dart';

class TextRenderer implements ComponentRenderer {
  @override
  Widget render(ComponentConfig config, {Map<String, dynamic>? dataContext}) {
    final dataKey = config.properties['dataKey'] as String?;
    String text;
    if (dataKey != null &&
        dataContext != null &&
        dataContext.containsKey(dataKey)) {
      text = dataContext[dataKey] as String;
    } else {
      text = config.properties['text'] as String? ?? 'Welcome';
    }
    //TODO
    //may need edit
    //we should take a decicsion where and how we will get the theme
    AppThemeModel? theme;
    if (dataContext != null && dataContext.containsKey('appTheme')) {
      theme = dataContext['appTheme'] as AppThemeModel?;
    }

    // Resolution: config.properties override → theme → defaults
    final fontSize =
        (config.properties['fontSize'] as num?)?.toDouble() ??
        theme?.fontSize ??
        18.0;
    final fontWeight = config.properties['fontWeight'] != null
        ? AppThemeModel.parseFontWeight(
            config.properties['fontWeight'] as String?,
          )
        : (theme?.fontWeight ?? FontWeight.w600);
    final fontStyle = config.properties['fontStyle'] != null
        ? AppThemeModel.parseFontStyle(
            config.properties['fontStyle'] as String?,
          )
        : (theme?.fontStyle ?? FontStyle.normal);
    //TODO: I think one keyWord is better
    final textColor =
        config.properties['textColor'] != null ||
            config.properties['color'] != null
        ? AppThemeModel.parseColor(
            (config.properties['textColor'] ?? config.properties['color'])
                as String?,
          )
        : theme?.text;

    return TextComponent(
      text: text,
      textColor: textColor,
      fontSize: fontSize,
      fontWeight: fontWeight,
      fontStyle: fontStyle,
    );
  }
}
