import 'package:flutter/widgets.dart';

import '../../core/enums/generic_component_type.dart';
import '../../config/genericConfig/component_config.dart';
import '../../config/genericConfig/screen_config.dart';
import 'renderers/button_renderer.dart';
import 'renderers/card_renderer.dart';
import 'renderers/column_renderer.dart';
import 'renderers/component_renderer.dart';
import 'renderers/container_renderer.dart';
import 'renderers/row_renderer.dart';
import 'renderers/scaffold_renderer.dart';
import 'renderers/text_renderer.dart';

/// Recursively renders a tree-based [ScreenConfig] into a widget tree.
class ScreenRenderer {
  final Map<GenericComponentType, ComponentRenderer> _renderers;

  ScreenRenderer(this._renderers);

  /// Creates a [ScreenRenderer] with all 7 primitive renderers wired.
  factory ScreenRenderer.withPrimitives() {
    return ScreenRenderer({
      GenericComponentType.scaffold: ScaffoldRenderer(),
      GenericComponentType.column: ColumnRenderer(),
      GenericComponentType.row: RowRenderer(),
      GenericComponentType.container: ContainerRenderer(),
      GenericComponentType.text: TextRenderer(),
      GenericComponentType.button: ButtonRenderer(),
      GenericComponentType.card: CardRenderer(),
    });
  }

  /// Renders the screen configuration into a widget.
  Widget render(ScreenConfig config, {Map<String, dynamic>? dataContext}) {
    return _buildComponent(config.root, dataContext);
  }

  Widget _buildComponent(
    ComponentConfig config, [
    Map<String, dynamic>? dataContext,
  ]) {
    final renderer = _renderers[config.type];
    if (renderer == null) {
      return const SizedBox.shrink();
    }
    return renderer.render(
      config,
      buildChild: (c) => _buildComponent(c, dataContext),
      dataContext: dataContext,
    );
  }
}
