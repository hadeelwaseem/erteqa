import 'package:flutter/material.dart';
import 'package:sooq_merchant/engine/component_renderer/component_renderer.dart';
import '../../config/component_config.dart';
import '../../core/widgets/stat_card.dart';
import '../../features/dashboard/domain/dashboard_data.dart';
import '../../config/models/app_theme_model.dart';
import '../../config/models/store_layout_model.dart';

class StatsSectionRenderer implements ComponentRenderer {
  @override
  Widget render(ComponentConfig config, {Map<String, dynamic>? dataContext}) {
    final dataKey = config.properties['dataKey'] as String?;
    final scrollDirection =
        config.properties['scrollDirection'] as String? ?? 'horizontal';

    List<StatData> stats = [];
    if (dataKey != null &&
        dataContext != null &&
        dataContext.containsKey(dataKey)) {
      final statsList = dataContext[dataKey];
      if (statsList is List<StatData>) {
        stats = statsList;
      }
    }

    if (stats.isEmpty) {
      return const SizedBox.shrink();
    }

    AppThemeModel? colors;
    StoreLayoutModel? layout;
    if (dataContext != null) {
      colors = dataContext['appTheme'] as AppThemeModel?;
      layout = dataContext['storeLayout'] as StoreLayoutModel?;
    }

    final isHorizontal = scrollDirection == 'horizontal';

    final statCards = stats.map((stat) {
      return Padding(
        padding: EdgeInsets.only(
          right: isHorizontal ? 12 : 0,
          bottom: isHorizontal ? 0 : 12,
        ),
        child: SizedBox(
          width: isHorizontal ? 145 : double.infinity,
          child: StatCard(
            icon: stat.icon,
            value: stat.value,
            label: stat.label,
            textColor: colors?.text,
            fontSize: colors?.fontSize,
            fontWeight: colors?.fontWeight,
            fontStyle: colors?.fontStyle,
            cardStyle: layout?.cardStyle,
          ),
        ),
      );
    }).toList();

    if (isHorizontal) {
      return SizedBox(
        height: 140,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: statCards),
        ),
      );
    } else {
      return Column(children: statCards);
    }
  }
}
