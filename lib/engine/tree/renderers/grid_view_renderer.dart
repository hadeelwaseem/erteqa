import 'package:flutter/widgets.dart';

import '../../../config/component_config.dart';
import '../../component_renderer/component_renderer.dart';
import '../../request_ui_state.dart';
import '../parsers/data_context_path.dart';
import '../parsers/property_parsers.dart';

class GridViewRenderer implements ComponentRenderer {
  @override
  Widget render(
    ComponentConfig config, {
    required ComponentWidgetBuilder buildChild,
    Map<String, dynamic>? dataContext,
  }) {
    final props = config.properties;
    final requestKey = resolveRequestKey(props);
    final crossAxisCount =
        config.crossAxisCount ?? _parseInt(config.properties['crossAxisCount']);
    final items = _resolveItems(config, dataContext);
    final phase = resolveRequestBoundListPhase(
      requestKey: requestKey,
      dataContext: dataContext,
      itemsEmpty: items.isEmpty,
    );

    if (phase == RequestBoundListPhase.loading ||
        phase == RequestBoundListPhase.error ||
        phase == RequestBoundListPhase.empty) {
      final requestMap = requestKey == null
          ? null
          : _requestMap(dataContext, requestKey);
      final message = switch (phase) {
        RequestBoundListPhase.error => resolveDisplayMessage(
          prop: props['errorMessage'] as String?,
          requestMap: requestMap,
          fallback: kDefaultErrorMessage,
        ),
        RequestBoundListPhase.empty => resolveDisplayMessage(
          prop: props['emptyMessage'] as String?,
          requestMap: requestMap,
          fallback: kDefaultEmptyMessage,
        ),
        _ => '',
      };
      return buildRequestPhasePlaceholder(phase: phase, message: message);
    }

    final scrollDirection = _parseAxis(
      config.scrollDirection ?? config.properties['scrollDirection'] as String?,
    );
    final mainAxisSpacing =
        config.mainAxisSpacing ??
        _parseDouble(config.properties['mainAxisSpacing']) ??
        0.0;
    final crossAxisSpacing =
        config.crossAxisSpacing ??
        _parseDouble(config.properties['crossAxisSpacing']) ??
        0.0;
    final childAspectRatio =
        PropertyParsers.parseDouble(config.properties['childAspectRatio']) ??
        1.0;

    final itemTemplate = config.itemBuilder?.item ?? config.child;
    final children = config.children ?? const <ComponentConfig>[];
    final enableInnerScroll = config.properties['enableInnerScroll'] == true;
    final shrinkWrap = !enableInnerScroll;
    final physics = enableInnerScroll
        ? null
        : const NeverScrollableScrollPhysics();

    if (crossAxisCount == null || crossAxisCount <= 0) {
      return _emptyState(props);
    }

    if (itemTemplate == null && children.isEmpty) {
      return _emptyState(props);
    }

    final delegate = SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: crossAxisCount,
      mainAxisSpacing: mainAxisSpacing,
      crossAxisSpacing: crossAxisSpacing,
      childAspectRatio: childAspectRatio,
    );

    if (itemTemplate != null) {
      if (items.isEmpty) return _emptyState(props);
      return GridView.builder(
        scrollDirection: scrollDirection,
        gridDelegate: delegate,
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

    return GridView.builder(
      scrollDirection: scrollDirection,
      gridDelegate: delegate,
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

  Map<String, dynamic>? _requestMap(
    Map<String, dynamic>? dataContext,
    String requestKey,
  ) {
    final requests = dataContext?['requests'];
    if (requests is! Map) return null;
    final entry = requests[requestKey];
    if (entry is Map<String, dynamic>) return entry;
    if (entry is Map) return Map<String, dynamic>.from(entry);
    return null;
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
      return resolveDataContextPath(dataContext, source);
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

  int? _parseInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }

  double? _parseDouble(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
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

  Widget _emptyState(Map<String, dynamic> props) {
    final message = resolveDisplayMessage(
      prop: props['emptyMessage'] as String?,
      requestMap: null,
      fallback: kDefaultEmptyMessage,
    );
    return Center(
      child: Text(message, textAlign: TextAlign.center),
    );
  }
}
