import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../core/enums/generic_component_type.dart';
import '../../config/component_config.dart';
import '../../config/screen_config.dart';
import '../../core/utils/app_logger.dart';
import '../tree/renderers/button_renderer.dart';
import '../tree/renderers/card_renderer.dart';
import '../tree/renderers/column_renderer.dart';
import '../component_renderer/component_renderer.dart';
import '../tree/renderers/app_bar_renderer.dart';
import '../tree/renderers/container_renderer.dart';
import '../tree/renderers/divider_renderer.dart';
import '../tree/renderers/icon_renderer.dart';
import '../tree/renderers/row_renderer.dart';
import '../tree/renderers/scaffold_renderer.dart';
import '../tree/renderers/text_renderer.dart';
import '../tree/renderers/spacer_renderer.dart';
import '../tree/renderers/image_renderer.dart';
import '../tree/renderers/rich_text_renderer.dart';
import '../tree/renderers/unsupported_component_renderer.dart';

/// Recursively renders a tree-based [ScreenConfig] into a widget tree.
///
/// The renderer uses a registry pattern with dependency injection support,
/// allowing custom renderers to be injected without modifying this class.
class ScreenRenderer {
  final Map<GenericComponentType, ComponentRenderer> _renderers;
  static const _pathKey = '_enginePath';

  /// Creates a [ScreenRenderer] with a custom renderer registry.
  ///
  /// Use this constructor for dependency injection and testing.
  /// Pass a map of component types to their renderer implementations.
  ScreenRenderer(this._renderers);

  /// Creates a [ScreenRenderer] with all 9 primitive renderers pre-configured.
  ///
  /// This is the default factory for typical usage. Use the main constructor
  /// if you need to inject custom renderers or override specific implementations.
  ///
  /// **Renderers included**:
  /// - Scaffold, Column, Row, Container (layout)
  /// - Text, Button (leaf widgets)
  /// - Card (material card)
  /// - Spacer, Image (new in Phase 1)
  factory ScreenRenderer.withPrimitives() {
    return ScreenRenderer(_createDefaultRenderers());
  }

  /// Creates the default renderer registry.
  ///
  /// Extracted as a static method to support:
  /// - Testing (can be mocked or overridden)
  /// - Custom renderer chains (start with defaults, override specific ones)
  /// - Serialization/inspection of available renderers
  static Map<GenericComponentType, ComponentRenderer>
  _createDefaultRenderers() {
    return {
      GenericComponentType.scaffold: ScaffoldRenderer(),
      GenericComponentType.column: ColumnRenderer(),
      GenericComponentType.row: RowRenderer(),
      GenericComponentType.container: ContainerRenderer(),
      GenericComponentType.text: TextRenderer(),
      GenericComponentType.button: ButtonRenderer(),
      GenericComponentType.card: CardRenderer(),
      GenericComponentType.spacer: SpacerRenderer(),
      GenericComponentType.image: ImageRenderer(),
      GenericComponentType.appBar: AppBarRenderer(),
      GenericComponentType.divider: DividerRenderer(),
      GenericComponentType.icon: IconRenderer(),
      GenericComponentType.richtext: RichTextRenderer(),
      GenericComponentType.unsupported: UnsupportedComponentRenderer(),
    };
  }

  /// Renders the screen configuration into a widget.
  Widget render(
    ScreenConfig config, {
    BuildContext? context,
    Map<String, dynamic>? dataContext,
  }) {
    return _buildComponent(
      config.root,
      dataContext: dataContext,
      context: context,
      variantId: config.pageId,
      path: 'root',
    );
  }

  /// Recursively builds a component widget from [ComponentConfig].
  ///
  /// Looks up the renderer for the component type and delegates rendering.
  /// Passes [buildChild] callback to support nested layouts like Row/Column.
  Widget _buildComponent(
    ComponentConfig config, {
    Map<String, dynamic>? dataContext,
    BuildContext? context,
    required String variantId,
    required String path,
  }) {
    AppLogger.debug(
      '[ScreenRenderer] render node type=${config.type.name} path=$path',
    );
    final renderer = _renderers[config.type];
    if (renderer == null) {
      final id = config.properties['id'] as String? ?? '?';
      AppLogger.debug(
        '[ScreenRenderer] ⚠️ No renderer found for type: ${config.type} '
        '(id="$id"). Did you forget to register it?',
      );
      return const SizedBox.shrink();
    }
    final onTap = _resolveTapAction(config, context, variantId);
    final renderConfig = onTap == null
        ? config
        : ComponentConfig(
            type: config.type,
            properties: {...config.properties, 'onTap': onTap},
            child: config.child,
            children: config.children,
          );
    final widget = renderer.render(
      renderConfig,
      buildChild: (c) => _buildComponent(
        c,
        dataContext: _withPath(dataContext, path),
        context: context,
        variantId: variantId,
        path: _childPath(path, config, c),
      ),
      dataContext: _withPath(dataContext, path),
    );
    if (onTap == null || config.type == GenericComponentType.button) {
      return widget;
    }
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: widget,
    );
  }

  VoidCallback? _resolveTapAction(
    ComponentConfig config,
    BuildContext? context,
    String variantId,
  ) {
    if (context == null) return null;
    final tap = config.properties['tap'];
    if (tap is! Map) return null;
    final tapType = tap['type'];
    if (tapType != 'navigate') return null;
    final route = tap['route'];
    if (route is! String || route.isEmpty) return null;
    // Navigate directly to the route — routes are first-class paths in the
    // ShellRoute setup (/products, /checkout, /product/1, etc.)
    return () {
      AppLogger.debug('[Engine] navigate to: $route');
      context.go(route);
    };
  }

  Map<String, dynamic> _withPath(
    Map<String, dynamic>? dataContext,
    String path,
  ) {
    final next = dataContext == null
        ? <String, dynamic>{}
        : Map<String, dynamic>.from(dataContext);
    next[_pathKey] = path;
    return next;
  }

  String _childPath(
    String parentPath,
    ComponentConfig parent,
    ComponentConfig child,
  ) {
    if (parent.child == child) {
      return '$parentPath.child';
    }
    final children = parent.children;
    if (children == null) return '$parentPath.child';
    final index = children.indexOf(child);
    return index == -1
        ? '$parentPath.children[?]'
        : '$parentPath.children[$index]';
  }
}
