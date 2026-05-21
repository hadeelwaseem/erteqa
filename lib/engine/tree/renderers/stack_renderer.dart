import 'package:flutter/widgets.dart';

import '../../../config/component_config.dart';
import '../../component_renderer/component_renderer.dart';
import '../parsers/property_parsers.dart';

/// Layers [children] back-to-front for splash overlays and similar layouts.
///
/// JSON `props`:
/// - `fit` — `expand` (default) | `loose`
///
/// Per-child `props` (on stack children):
/// - `stackLayer` — `fill` | `positioned` (index 0 defaults to `fill`)
/// - `stackAlign` — alignment string when `positioned` (default `bottomCenter`)
/// - `stackInsetBottom` — px from screen bottom (uses [Positioned] bottom; preferred for footers)
/// - `stackWidthFactor` — `1` = full width when using [Align]
class StackRenderer implements ComponentRenderer {
  @override
  Widget render(
    ComponentConfig config, {
    required ComponentWidgetBuilder buildChild,
    Map<String, dynamic>? dataContext,
  }) {
    final children = config.children ?? [];
    final fit = (config.properties['fit'] as String? ?? 'expand').toLowerCase();

    if (children.isEmpty) {
      return const SizedBox.shrink();
    }

    final stackChildren = <Widget>[
      for (var i = 0; i < children.length; i++)
        _wrapStackChild(
          buildChild(children[i]),
          childConfig: children[i],
          index: i,
        ),
    ];

    final stack = Stack(
      fit: fit == 'loose' ? StackFit.loose : StackFit.expand,
      children: stackChildren,
    );

    if (fit == 'loose') {
      return stack;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : MediaQuery.sizeOf(context).height;
        return SizedBox(width: double.infinity, height: height, child: stack);
      },
    );
  }

  Widget _wrapStackChild(
    Widget child, {
    required ComponentConfig childConfig,
    required int index,
  }) {
    final layer =
        (childConfig.properties['stackLayer'] as String? ??
                (index == 0 ? 'fill' : 'positioned'))
            .toLowerCase();

    if (layer == 'fill') {
      return Positioned.fill(child: child);
    }

    final insetBottom = PropertyParsers.parseDouble(
      childConfig.properties['stackInsetBottom'],
    );
    if (insetBottom != null && insetBottom >= 0) {
      return Positioned(
        left: 0,
        right: 0,
        bottom: insetBottom,
        child: Align(
          alignment: Alignment.bottomCenter,
          widthFactor: PropertyParsers.parseDouble(
                childConfig.properties['stackWidthFactor'],
              ) ??
              1,
          child: child,
        ),
      );
    }

    final alignment =
        PropertyParsers.parseAlignment(
          childConfig.properties['stackAlign'] as String?,
        ) ??
        Alignment.bottomCenter;
    final widthFactor = PropertyParsers.parseDouble(
      childConfig.properties['stackWidthFactor'],
    );

    return Positioned.fill(
      child: Align(
        alignment: alignment,
        widthFactor: widthFactor,
        child: child,
      ),
    );
  }
}
