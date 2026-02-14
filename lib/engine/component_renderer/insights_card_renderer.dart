import 'package:flutter/material.dart';
import 'package:sooq_merchant/engine/component_renderer/component_renderer.dart';
import '../../config/component_config.dart';
import '../../core/widgets/insights_card.dart';
import '../../features/dashboard/domain/dashboard_data.dart';
import '../../config/models/app_theme_model.dart';
import '../../config/models/store_layout_model.dart';

class InsightsCardRenderer implements ComponentRenderer {
  @override
  Widget render(ComponentConfig config, {Map<String, dynamic>? dataContext}) {
    final dataKey = config.properties['dataKey'] as String?;
    InsightsData? insights;

    if (dataKey != null &&
        dataContext != null &&
        dataContext.containsKey(dataKey)) {
      final insightsData = dataContext[dataKey];
      if (insightsData is InsightsData) {
        insights = insightsData;
      }
    }

    AppThemeModel? colors;
    StoreLayoutModel? layout;
    if (dataContext != null) {
      colors = dataContext['appTheme'] as AppThemeModel?;
      layout = dataContext['storeLayout'] as StoreLayoutModel?;
    }

    final textColor = config.properties['textColor'] != null ||
            config.properties['color'] != null
        ? AppThemeModel.parseColor(
            (config.properties['textColor'] ?? config.properties['color'])
                as String?,
          )
        : colors?.text;
    final fontSize =
        (config.properties['fontSize'] as num?)?.toDouble() ?? colors?.fontSize ?? 14.0;
    final fontWeight = config.properties['fontWeight'] != null
        ? AppThemeModel.parseFontWeight(
            config.properties['fontWeight'] as String?,
          )
        : (colors?.fontWeight ?? FontWeight.normal);
    final fontStyle = config.properties['fontStyle'] != null
        ? AppThemeModel.parseFontStyle(
            config.properties['fontStyle'] as String?,
          )
        : (colors?.fontStyle ?? FontStyle.normal);

    if (insights == null) {
      final message =
          config.properties['message'] as String? ?? 'No insights available';
      final iconName = config.properties['icon'] as String?;
      final icon = _getIconFromString(iconName ?? 'trending_up');

      return InsightsCard(
        message: message,
        icon: icon,
        textColor: textColor,
        fontSize: fontSize,
        fontWeight: fontWeight,
        fontStyle: fontStyle,
        cardStyle: layout?.cardStyle,
      );
    }

    return InsightsCard(
      message: insights.message,
      icon: insights.icon,
      textColor: textColor,
      fontSize: fontSize,
      fontWeight: fontWeight,
      fontStyle: fontStyle,
      cardStyle: layout?.cardStyle,
    );
  }

  IconData _getIconFromString(String iconName) {
    switch (iconName) {
      case 'trending_up':
        return Icons.trending_up;
      case 'trending_down':
        return Icons.trending_down;
      case 'info':
        return Icons.info;
      default:
        return Icons.trending_up;
    }
  }
}
