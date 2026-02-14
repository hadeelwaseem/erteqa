import 'package:flutter/material.dart';
import 'package:sooq_merchant/engine/component_renderer/component_renderer.dart';
import '../../config/component_config.dart';
import '../../core/widgets/stat_card.dart';
import '../../config/models/app_theme_model.dart';
import '../../config/models/store_layout_model.dart';

class StatCardRenderer implements ComponentRenderer {
  @override
  Widget render(ComponentConfig config, {Map<String, dynamic>? dataContext}) {
    final iconName = config.properties['icon'] as String?;
    final value = config.properties['value'] as String? ?? '';
    final label = config.properties['label'] as String? ?? '';

    final icon = iconName != null ? _getIconFromString(iconName) : Icons.info;

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
        (config.properties['fontSize'] as num?)?.toDouble() ??
            colors?.fontSize ??
            16.0;
    final fontWeight = config.properties['fontWeight'] != null
        ? AppThemeModel.parseFontWeight(
            config.properties['fontWeight'] as String?,
          )
        : (colors?.fontWeight ?? FontWeight.bold);
    final fontStyle = config.properties['fontStyle'] != null
        ? AppThemeModel.parseFontStyle(
            config.properties['fontStyle'] as String?,
          )
        : (colors?.fontStyle ?? FontStyle.normal);

    return StatCard(
      icon: icon,
      value: value,
      label: label,
      textColor: textColor,
      fontSize: fontSize,
      fontWeight: fontWeight,
      fontStyle: fontStyle,
      cardStyle: layout?.cardStyle,
    );
  }

  IconData _getIconFromString(String iconName) {
    switch (iconName) {
      case 'attach_money':
        return Icons.attach_money;
      case 'receipt_long':
        return Icons.receipt_long;
      case 'inventory_2_outlined':
        return Icons.inventory_2_outlined;
      case 'people':
        return Icons.people;
      default:
        return Icons.info;
    }
  }
}
