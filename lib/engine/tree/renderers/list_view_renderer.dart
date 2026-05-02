import 'package:flutter/widgets.dart';

import '../../../config/component_config.dart';
import '../../component_renderer/component_renderer.dart';

class ListViewRenderer implements ComponentRenderer {
  @override
  Widget render(
    ComponentConfig config, {
    required ComponentWidgetBuilder buildChild,
    Map<String, dynamic>? dataContext,
  }) {
    final scrollDirection = _parseAxis(
      config.scrollDirection ?? config.properties['scrollDirection'] as String?,
    );

    final itemTemplate = config.itemBuilder?.item ?? config.child;
    final children = config.children ?? const <ComponentConfig>[];
    final items = _resolveItems(config, dataContext);
    final enableInnerScroll = config.properties['enableInnerScroll'] == true;
    final shrinkWrap = !enableInnerScroll;
    final physics = enableInnerScroll
        ? null
        : const NeverScrollableScrollPhysics();

    if (itemTemplate == null && children.isEmpty) {
      return _emptyState();
    }

    if (itemTemplate != null) {
      if (items.isEmpty) return _emptyState();
      return ListView.builder(
        scrollDirection: scrollDirection,
        shrinkWrap: shrinkWrap,
        physics: physics,
        primary: enableInnerScroll ? null : false,
        itemCount: items.length,
        itemBuilder: (context, index) {
          final scoped = _withItemContext(
            itemTemplate,
            dataContext,
            items[index],
            index,
          );
          return buildChild(scoped);
        },
      );
    }

    return ListView.builder(
      scrollDirection: scrollDirection,
      shrinkWrap: shrinkWrap,
      physics: physics,
      primary: enableInnerScroll ? null : false,
      itemCount: children.length,
      itemBuilder: (context, index) {
        final scoped = _withItemContext(
          children[index],
          dataContext,
          items.length > index ? items[index] : null,
          index,
        );
        return buildChild(scoped);
      },
    );
  }

  Axis _parseAxis(String? axis) {
    if (axis == 'horizontal') return Axis.horizontal;
    return Axis.vertical;
  }

  List<dynamic> _resolveItems(
    ComponentConfig config,
    Map<String, dynamic>? dataContext,
  ) {
    final builder = config.itemBuilder;
    if (builder != null) {
      if (builder.source != null) {
        final raw = _resolveSource(builder.source!, config, dataContext);
        final resolved = _normalizeListOrNull(raw);
        if (resolved != null) return resolved;
      }
      if (builder.staticItems != null) return builder.staticItems!;
    }

    return _normalizeList(config.properties['items']);
  }

  dynamic _resolveSource(
    String source,
    ComponentConfig config,
    Map<String, dynamic>? dataContext,
  ) {
    if (source == 'dataContext') return dataContext;
    if (source == 'props') return config.properties;

    if (source.startsWith('dataContext.')) {
      final path = source.substring('dataContext.'.length);
      return _readPath(dataContext, path);
    }
    if (source.startsWith('props.')) {
      final path = source.substring('props.'.length);
      return _readPath(config.properties, path);
    }
    return null;
  }

  dynamic _readPath(Map<String, dynamic>? root, String path) {
    if (root == null || path.isEmpty) return null;
    dynamic current = root;
    for (final segment in path.split('.')) {
      if (current is Map<String, dynamic> && current.containsKey(segment)) {
        current = current[segment];
      } else {
        return null;
      }
    }
    return current;
  }

  List<dynamic>? _normalizeListOrNull(dynamic raw) {
    if (raw is List) return raw;
    return null;
  }

  List<dynamic> _normalizeList(dynamic raw) {
    return _normalizeListOrNull(raw) ?? const <dynamic>[];
  }

  ComponentConfig _withItemContext(
    ComponentConfig template,
    Map<String, dynamic>? dataContext,
    dynamic item,
    int index,
  ) {
    final override = <String, dynamic>{
      if (item != null) 'item': item,
      'index': index,
    };
    final merged = dataContext == null
        ? override
        : {...dataContext, ...override};

    return ComponentConfig(
      type: template.type,
      properties: template.properties,
      child: template.child,
      children: template.children,
      itemBuilder: template.itemBuilder,
      axis: template.axis,
      scrollDirection: template.scrollDirection,
      crossAxisCount: template.crossAxisCount,
      mainAxisSpacing: template.mainAxisSpacing,
      crossAxisSpacing: template.crossAxisSpacing,
      dataContextOverride: merged,
    );
  }

  Widget _emptyState() {
    return const Center(
      child: Text('No items available', textAlign: TextAlign.center),
    );
  }
}
