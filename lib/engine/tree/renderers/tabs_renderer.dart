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
/// Static items: [data.items] or [data.staticItems]. Dynamic: [itemsPath]
/// with optional [itemLabelPath] / [itemValuePath] (prefixed by staticItems).
/// Tab tap dispatches JSON [tap] with the full item in `dataContext['tap']`.
class TabsRenderer implements ComponentRenderer {
  @override
  Widget render(
    ComponentConfig config, {
    required ComponentWidgetBuilder buildChild,
    Map<String, dynamic>? dataContext,
  }) {
    final properties = config.properties;
    final items = _resolveItems(properties, dataContext);
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
    final scrollHorizontal = properties['scroll'] != 'vertical';

    return Builder(
      builder: (context) {
        final dispatcher = _resolveDispatcher(dataContext, context);

        final chips = [
          for (final item in items)
            Padding(
              padding: EdgeInsets.only(
                right: scrollHorizontal ? spacing : 0,
                bottom: scrollHorizontal ? 0 : runSpacing,
              ),
              child: _TabChip(
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
                        merged['tap'] = Map<String, dynamic>.from(item.payload);
                        dispatcher.dispatch(tapMap, dataContext: merged);
                      },
              ),
            ),
        ];

        if (scrollHorizontal) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: chips,
            ),
          );
        }

        return Wrap(
          spacing: spacing,
          runSpacing: runSpacing,
          children: chips,
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

  List<_TabItem> _resolveItems(
    Map<String, dynamic> properties,
    Map<String, dynamic>? dataContext,
  ) {
    final data = properties['data'];
    final staticPrefix = _parseStaticItems(
      data is Map ? data['staticItems'] : null,
      startIndex: 0,
    );
    if (staticPrefix.isEmpty && data is Map && data['items'] is List) {
      return _parseStaticItems(data['items'], startIndex: 0);
    }

    final itemsPath = properties['itemsPath'] as String?;
    if (itemsPath != null && itemsPath.isNotEmpty) {
      final raw = resolveDataContextPath(dataContext, itemsPath);
      final dynamicItems = _mapDynamicItems(
        raw,
        properties,
        startIndex: staticPrefix.length,
      );
      return [...staticPrefix, ...dynamicItems];
    }

    if (staticPrefix.isNotEmpty) {
      return staticPrefix;
    }

    if (data is Map && data['items'] is List) {
      return _parseStaticItems(data['items'], startIndex: 0);
    }
    return const [];
  }

  List<_TabItem> _parseStaticItems(
    dynamic rawItems, {
    required int startIndex,
  }) {
    if (rawItems is! List) return const [];

    final result = <_TabItem>[];
    for (var i = 0; i < rawItems.length; i++) {
      final entry = rawItems[i];
      if (entry is! Map) continue;
      final map = Map<String, dynamic>.from(entry);
      final title = map['title']?.toString() ?? '';
      final indexRaw = map['index'];
      final index = indexRaw is int
          ? indexRaw
          : indexRaw is num
          ? indexRaw.toInt()
          : startIndex + i;
      map['index'] = index;
      result.add(_TabItem(title: title, index: index, payload: map));
    }
    return result;
  }

  List<_TabItem> _mapDynamicItems(
    dynamic raw,
    Map<String, dynamic> properties, {
    required int startIndex,
  }) {
    if (raw is! List) return const [];

    final flattenMode = properties['flattenItems'] as String?;
    final rows = flattenMode == 'leaves' || flattenMode == 'all'
        ? _flattenCategoryRows(raw, leavesOnly: flattenMode == 'leaves')
        : raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();

    final labelPath = properties['itemLabelPath'] as String?;
    final valuePath = properties['itemValuePath'] as String?;
    final valueField = valuePath?.isNotEmpty == true ? valuePath! : 'slug';

    final result = <_TabItem>[];
    for (var i = 0; i < rows.length; i++) {
      final map = rows[i];
      final label = _readItemField(map, labelPath, const [
        'name',
        'nameAr',
        'title',
        'label',
      ]);
      final value = _readItemField(map, valuePath, const [
        'slug',
        'value',
        'id',
        'categoryId',
      ]);
      if (value.isEmpty) continue;

      final index = startIndex + result.length;
      map['title'] = label.isEmpty ? value : label;
      map['index'] = index;
      map[valueField] = value;
      result.add(
        _TabItem(
          title: map['title'] as String,
          index: index,
          payload: map,
        ),
      );
    }
    return result;
  }

  /// Expands nested category `children` for API-driven tabs.
  List<Map<String, dynamic>> _flattenCategoryRows(
    List<dynamic> raw, {
    required bool leavesOnly,
  }) {
    final flat = <Map<String, dynamic>>[];

    void walk(Map<String, dynamic> map) {
      final children = map['children'];
      final childMaps = children is List
          ? children
              .whereType<Map>()
              .map((child) => Map<String, dynamic>.from(child))
              .toList()
          : const <Map<String, dynamic>>[];

      if (leavesOnly && childMaps.isNotEmpty) {
        for (final child in childMaps) {
          walk(child);
        }
        return;
      }

      flat.add(map);
      for (final child in childMaps) {
        walk(child);
      }
    }

    for (final entry in raw) {
      if (entry is Map) {
        walk(Map<String, dynamic>.from(entry));
      }
    }
    return flat;
  }

  String _readItemField(
    Map<dynamic, dynamic> entry,
    String? explicitPath,
    List<String> fallbacks,
  ) {
    if (explicitPath != null && explicitPath.isNotEmpty) {
      final v = entry[explicitPath]?.toString().trim() ?? '';
      if (v.isNotEmpty) return v;
    }
    for (final key in fallbacks) {
      final v = entry[key]?.toString().trim() ?? '';
      if (v.isNotEmpty) return v;
    }
    return '';
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
  const _TabItem({
    required this.title,
    required this.index,
    required this.payload,
  });

  final String title;
  final int index;
  final Map<String, dynamic> payload;
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
