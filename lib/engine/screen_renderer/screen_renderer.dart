import 'package:flutter/widgets.dart';

import '../../core/enums/generic_component_type.dart';
import '../../config/component_config.dart';
import '../../config/screen_config.dart';
import '../tree/renderers/button_renderer.dart';
import '../tree/renderers/card_renderer.dart';
import '../tree/renderers/column_renderer.dart';
import '../component_renderer/component_renderer.dart';
import '../tree/renderers/container_renderer.dart';
import '../tree/renderers/row_renderer.dart';
import '../tree/renderers/scaffold_renderer.dart';
import '../tree/renderers/text_renderer.dart';

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
