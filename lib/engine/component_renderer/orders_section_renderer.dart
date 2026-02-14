import 'package:flutter/material.dart';
import 'package:sooq_merchant/engine/component_renderer/component_renderer.dart';
import '../../config/component_config.dart';
import '../../core/widgets/order_tile.dart';
import '../../features/dashboard/domain/dashboard_data.dart';
import '../../config/models/app_theme_model.dart';
import '../../config/models/store_layout_model.dart';

class OrdersSectionRenderer implements ComponentRenderer {
  @override
  Widget render(ComponentConfig config, {Map<String, dynamic>? dataContext}) {
    final dataKey = config.properties['dataKey'] as String?;
    final maxItems = config.properties['maxItems'] as int?;
    final title = config.properties['title'] as String? ?? 'Recent Orders';

    List<OrderData> orders = [];
    if (dataKey != null &&
        dataContext != null &&
        dataContext.containsKey(dataKey)) {
      final ordersList = dataContext[dataKey];
      if (ordersList is List<OrderData>) {
        orders = ordersList;
      }
    }

    if (maxItems != null && maxItems < orders.length) {
      orders = orders.take(maxItems).toList();
    }

    AppThemeModel? colors;
    StoreLayoutModel? layout;
    if (dataContext != null) {
      colors = dataContext['appTheme'] as AppThemeModel?;
      layout = dataContext['storeLayout'] as StoreLayoutModel?;
    }

    final titleFontSize =
        (config.properties['titleFontSize'] as num?)?.toDouble() ??
            colors?.fontSize ??
            16.0;
    final titleFontWeight = config.properties['titleFontWeight'] != null
        ? AppThemeModel.parseFontWeight(
            config.properties['titleFontWeight'] as String?,
          )
        : (colors?.fontWeight ?? FontWeight.w600);
    final titleColor = config.properties['titleColor'] != null
        ? AppThemeModel.parseColor(
            config.properties['titleColor'] as String?,
          )
        : colors?.text;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: titleFontSize,
            fontWeight: titleFontWeight,
            color: titleColor,
            fontStyle: colors?.fontStyle ?? FontStyle.normal,
          ),
        ),
        const SizedBox(height: 12),
        ...orders.map((order) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: OrderTile(
              status: order.status,
              color: order.color,
              amount: order.amount,
              icon: order.icon,
              textColor: colors?.text,
              fontSize: colors?.fontSize,
              fontWeight: colors?.fontWeight,
              fontStyle: colors?.fontStyle,
              cardStyle: layout?.cardStyle,
            ),
          );
        }).toList(),
      ],
    );
  }
}
