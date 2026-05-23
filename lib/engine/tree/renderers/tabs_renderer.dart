import 'package:flutter/material.dart';

import '../../../config/component_config.dart';
import '../../actions/action_dispatcher.dart';
import '../../component_renderer/component_renderer.dart';
import '../../theme/engine_theme.dart';
import '../parsers/data_context_path.dart';
import '../parsers/property_parsers.dart';

/// In-page segment tabs (not bottom [navigation.tabs] shell).
///
/// Controlled: [selectedIndex] or [selectedIndexPath] from [dataContext].
/// Tab tap dispatches JSON [tap] with `dataContext['tap']['index']`.
class TabsRenderer implements ComponentRenderer {
  @override
  Widget render(
    ComponentConfig config, {
    required ComponentWidgetBuilder buildChild,
    Map<String, dynamic>? dataContext,
  }) {
    final properties = config.properties;
    final data = properties['data'];
    final items = _parseItems(data);
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = EngineTheme.fromDataContext(dataContext);
    final selectedIndex = _resolveSelectedIndex(properties, dataContext);
    final spacing = PropertyParsers.parseDouble(properties['spacing']) ?? 6.0;
    final runSpacing =
        PropertyParsers.parseDouble(properties['runSpacing']) ?? 4.0;
    final activeColor = PropertyParsers.parseColor(
          properties['activeColor'] as String?,
        ) ??
        theme?.primaryColor ??
        const Color(0xFFF97316);
    final inactiveColor = PropertyParsers.parseColor(
          properties['inactiveColor'] as String?,
        ) ??
        theme?.textColor ??
        const Color(0xFF0F172A);
    final indicatorWidth =
        PropertyParsers.parseDouble(properties['indicatorWidth']) ?? 2.0;

    final tapAction = properties['tap'];
    final tapMap = tapAction is Map<String, dynamic> ? tapAction : null;

    return Builder(
      builder: (context) {
        final dispatcher = _resolveDispatcher(dataContext, context);

        return Wrap(
          spacing: spacing,
          runSpacing: runSpacing,
          children: [
            for (final item in items)
              _TabChip(
                title: item.title,
                isActive: item.index == selectedIndex,
                activeColor: activeColor,
                inactiveColor: inactiveColor,
                indicatorWidth: indicatorWidth,
                onTap: tapMap == null || dispatcher == null
                    ? null
                    : () {
                        final merged = Map<String, dynamic>.from(
                          dataContext ?? <String, dynamic>{},
                        );
                        merged['tap'] = {'index': item.index};
                        dispatcher.dispatch(tapMap, dataContext: merged);
                      },
              ),
          ],
        );
      },
    );
  }

  int _resolveSelectedIndex(
    Map<String, dynamic> properties,
    Map<String, dynamic>? dataContext,
  ) {
    final path = properties['selectedIndexPath'] as String?;
    if (path != null && path.isNotEmpty) {
      final fromContext = resolveDataContextPath(dataContext, path);
      if (fromContext is int) return fromContext;
      if (fromContext is num) return fromContext.toInt();
      if (fromContext is String) {
        final parsed = int.tryParse(fromContext);
        if (parsed != null) return parsed;
      }
    }
    final staticIndex = properties['selectedIndex'];
    if (staticIndex is int) return staticIndex;
    if (staticIndex is num) return staticIndex.toInt();
    if (staticIndex is String) return int.tryParse(staticIndex) ?? 0;
    return 0;
  }

  List<_TabItem> _parseItems(dynamic data) {
    if (data is! Map) return const [];
    final rawItems = data['items'];
    if (rawItems is! List) return const [];

    final result = <_TabItem>[];
    for (var i = 0; i < rawItems.length; i++) {
      final entry = rawItems[i];
      if (entry is! Map) continue;
      final title = entry['title']?.toString() ?? '';
      final indexRaw = entry['index'];
      final index = indexRaw is int
          ? indexRaw
          : indexRaw is num
          ? indexRaw.toInt()
          : i;
      result.add(_TabItem(title: title, index: index));
    }
    return result;
  }

  EngineActionDispatcher? _resolveDispatcher(
    Map<String, dynamic>? dataContext,
    BuildContext context,
  ) {
    if (dataContext != null) {
      final existing = dataContext[EngineActionDispatcher.contextKey];
      if (existing is EngineActionDispatcher) return existing;
    }
    final dispatcher = EngineActionDispatcher(context: context);
    dataContext?[EngineActionDispatcher.contextKey] = dispatcher;
    return dispatcher;
  }
}

class _TabItem {
  const _TabItem({required this.title, required this.index});

  final String title;
  final int index;
}

class _TabChip extends StatelessWidget {
  const _TabChip({
    required this.title,
    required this.isActive,
    required this.activeColor,
    required this.inactiveColor,
    required this.indicatorWidth,
    this.onTap,
  });

  final String title;
  final bool isActive;
  final Color activeColor;
  final Color inactiveColor;
  final double indicatorWidth;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? activeColor : inactiveColor;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isActive ? activeColor : Colors.transparent,
                width: indicatorWidth,
              ),
            ),
          ),
          child: Text(
            title,
            style: TextStyle(
              color: color,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}
