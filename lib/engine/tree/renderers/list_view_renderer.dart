import 'package:flutter/widgets.dart';

import '../../../config/component_config.dart';
import '../../component_renderer/component_renderer.dart';
import '../../request_ui_state.dart';
import '../../skeleton/request_bound_skeleton.dart';
import '../../skeleton/skeleton_item_factory.dart';
import '../parsers/data_context_path.dart';
import '../parsers/property_parsers.dart';

class ListViewRenderer implements ComponentRenderer {
  @override
  Widget render(
    ComponentConfig config, {
    required ComponentWidgetBuilder buildChild,
    Map<String, dynamic>? dataContext,
  }) {
    final props = config.properties;
    final requestKey = resolveRequestKey(props);
    final items = _resolveItems(config, dataContext);
    final phase = resolveRequestBoundListPhase(
      requestKey: requestKey,
      dataContext: dataContext,
      itemsEmpty: items.isEmpty,
    );

    final scrollDirection = _parseAxis(
      config.scrollDirection ?? config.properties['scrollDirection'] as String?,
    );
    final isHorizontal = scrollDirection == Axis.horizontal;
    final boundedHeight = PropertyParsers.parseDouble(props['height']) ??
        (isHorizontal ? 72.0 : null);

    final itemTemplate = config.itemBuilder?.item ?? config.child;

    if (phase == RequestBoundListPhase.loading) {
      if (itemTemplate != null) {
        final count = SkeletonItemFactory.resolveCount(
          props: props,
          isHorizontal: isHorizontal,
        );
        final fakeItems = SkeletonItemFactory.items(count);
        final skeletonContext = RequestBoundSkeleton.skeletonContext(
          dataContext,
        );
        final listView = ListView.builder(
          scrollDirection: scrollDirection,
          shrinkWrap: true,
          physics: isHorizontal
              ? const ClampingScrollPhysics()
              : const NeverScrollableScrollPhysics(),
          primary: false,
          itemCount: count,
          itemBuilder: (context, index) {
            final scoped = _withItemContext(
              itemTemplate,
              skeletonContext,
              fakeItems[index],
              index,
            );
            return buildChild(scoped);
          },
        );
        Widget skeletonList = RequestBoundSkeleton.wrap(
          child: listView,
          dataContext: dataContext,
        );
        if (isHorizontal && boundedHeight != null) {
          skeletonList = SizedBox(height: boundedHeight, child: skeletonList);
        }
        return skeletonList;
      }
      return buildRequestPhasePlaceholder(
        phase: phase,
        message: '',
        compact: isHorizontal,
      );
    }

    if (phase == RequestBoundListPhase.error ||
        phase == RequestBoundListPhase.empty) {
      final requestMap = requestKey == null
          ? null
          : requestMapForKey(dataContext, requestKey);
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
      return buildRequestPhasePlaceholder(
        phase: phase,
        message: message,
        compact: isHorizontal,
      );
    }

    final children = config.children ?? const <ComponentConfig>[];

    if (itemTemplate == null && children.isEmpty) {
      return _emptyState(props, compact: isHorizontal);
    }

    if (itemTemplate != null && items.isEmpty) {
      return _emptyState(props, compact: isHorizontal);
    }

    final listView = itemTemplate != null
        ? ListView.builder(
            scrollDirection: scrollDirection,
            shrinkWrap: true,
            physics: isHorizontal
                ? const ClampingScrollPhysics()
                : const NeverScrollableScrollPhysics(),
            primary: false,
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
          )
        : ListView.builder(
            scrollDirection: scrollDirection,
            shrinkWrap: true,
            physics: isHorizontal
                ? const ClampingScrollPhysics()
                : const NeverScrollableScrollPhysics(),
            primary: false,
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

    if (isHorizontal && boundedHeight != null) {
      return SizedBox(height: boundedHeight, child: listView);
    }
    return listView;
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

  Widget _emptyState(Map<String, dynamic> props, {required bool compact}) {
    final prop = props['emptyMessage'] as String?;
    if (prop == null || prop.trim().isEmpty) {
      return const SizedBox.shrink();
    }
    final message = resolveDisplayMessage(
      prop: prop,
      requestMap: null,
      fallback: kDefaultEmptyMessage,
    );
    if (compact) {
      return const SizedBox.shrink();
    }
    return buildRequestPhasePlaceholder(
      phase: RequestBoundListPhase.empty,
      message: message,
    );
  }
}
