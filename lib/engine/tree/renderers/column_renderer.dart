import 'package:flutter/material.dart';

import '../../../config/component_config.dart';
import '../../../core/enums/generic_component_type.dart';

import '../../component_renderer/component_renderer.dart';
import '../parsers/property_parsers.dart';

class ColumnRenderer implements ComponentRenderer {
  @override
  Widget render(
    ComponentConfig config, {
    required ComponentWidgetBuilder buildChild,
    Map<String, dynamic>? dataContext,
  }) {
    final mainAxisAlignment = PropertyParsers.parseMainAxisAlignment(
      config.properties['mainAxisAlignment'] as String?,
    );
    final crossAxisAlignment = PropertyParsers.parseCrossAxisAlignment(
      config.properties['crossAxisAlignment'] as String?,
    );
    final mainAxisSize = PropertyParsers.parseMainAxisSize(
      config.properties['mainAxisSize'] as String?,
      defaultValue: MainAxisSize.min,
    );
    final textDirection = PropertyParsers.parseTextDirection(
      config.properties['textDirection'] as String?,
    );
    final children = config.layoutChildren;
    final gap = PropertyParsers.parseDouble(config.properties['gap']) ?? 0;
    final wantsFlex = mainAxisSize == MainAxisSize.max &&
        children.any(_isExpandContainer);
    final padding = PropertyParsers.parseEdgeInsetsDirectional(
      config.properties['padding'],
    );
    final safeAreaBody = config.properties['safeAreaBody'] == true;

    if (safeAreaBody && children.isNotEmpty) {
      final hasAppBar = children.first.type == GenericComponentType.appBar;
      if (hasAppBar && children.length > 1) {
        return _renderWithAppBarAndSafeBody(
          config: config,
          buildChild: buildChild,
          appBarConfig: children.first,
          bodyConfigs: children.sublist(1),
          mainAxisAlignment: mainAxisAlignment,
          crossAxisAlignment: crossAxisAlignment,
          mainAxisSize: mainAxisSize,
          textDirection: textDirection,
          gap: gap,
          wantsFlex: wantsFlex,
          padding: padding,
        );
      }
      if (!hasAppBar) {
        return SafeArea(
          child: _renderColumn(
            config: config,
            buildChild: buildChild,
            children: children,
            mainAxisAlignment: mainAxisAlignment,
            crossAxisAlignment: crossAxisAlignment,
            mainAxisSize: mainAxisSize,
            textDirection: textDirection,
            gap: gap,
            wantsFlex: wantsFlex,
            padding: padding,
          ),
        );
      }
    }

    return _renderColumn(
      config: config,
      buildChild: buildChild,
      children: children,
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      mainAxisSize: mainAxisSize,
      textDirection: textDirection,
      gap: gap,
      wantsFlex: wantsFlex,
      padding: padding,
    );
  }

  Widget _renderWithAppBarAndSafeBody({
    required ComponentConfig config,
    required ComponentWidgetBuilder buildChild,
    required ComponentConfig appBarConfig,
    required List<ComponentConfig> bodyConfigs,
    required MainAxisAlignment mainAxisAlignment,
    required CrossAxisAlignment crossAxisAlignment,
    required MainAxisSize mainAxisSize,
    required TextDirection? textDirection,
    required double gap,
    required bool wantsFlex,
    required EdgeInsetsDirectional? padding,
  }) {
    final appBarWidget = buildChild(appBarConfig);
    final bodyColumn = _renderColumn(
      config: config,
      buildChild: buildChild,
      children: bodyConfigs,
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      mainAxisSize: mainAxisSize,
      textDirection: textDirection,
      gap: gap,
      wantsFlex: wantsFlex,
      padding: null,
    );
    final safeBody = SafeArea(top: false, child: bodyColumn);

    Widget buildSplitColumn({required bool useExpanded}) {
      return Column(
        mainAxisSize: mainAxisSize,
        crossAxisAlignment: crossAxisAlignment,
        textDirection: textDirection,
        children: [
          appBarWidget,
          if (useExpanded && mainAxisSize == MainAxisSize.max)
            Expanded(child: safeBody)
          else
            safeBody,
        ],
      );
    }

    Widget column = buildSplitColumn(useExpanded: false);

    if (padding != null) {
      column = Padding(padding: padding, child: column);
    }

    if (mainAxisSize != MainAxisSize.max || !wantsFlex) {
      return column;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (!constraints.maxHeight.isFinite) {
          return column;
        }
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : double.infinity;
        return SizedBox(
          width: width,
          height: constraints.maxHeight,
          child: buildSplitColumn(useExpanded: true),
        );
      },
    );
  }

  Widget _renderColumn({
    required ComponentConfig config,
    required ComponentWidgetBuilder buildChild,
    required List<ComponentConfig> children,
    required MainAxisAlignment mainAxisAlignment,
    required CrossAxisAlignment crossAxisAlignment,
    required MainAxisSize mainAxisSize,
    required TextDirection? textDirection,
    required double gap,
    required bool wantsFlex,
    required EdgeInsetsDirectional? padding,
  }) {
    Widget buildColumn({required bool useExpanded}) {
      final built = <Widget>[
        for (final c in children)
          _wrapColumnChild(
            buildChild(c),
            config: c,
            useExpanded: useExpanded,
          ),
      ];
      final childWidgets = _withGap(built, gap);
      Widget column = Column(
        mainAxisSize: mainAxisSize,
        mainAxisAlignment: mainAxisAlignment,
        crossAxisAlignment: crossAxisAlignment,
        textDirection: textDirection,
        children: childWidgets,
      );
      if (padding != null) {
        column = Padding(padding: padding, child: column);
      }
      return column;
    }

    if (!wantsFlex) {
      return buildColumn(useExpanded: false);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (!constraints.maxHeight.isFinite) {
          return buildColumn(useExpanded: false);
        }
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : double.infinity;
        return SizedBox(
          width: width,
          height: constraints.maxHeight,
          child: buildColumn(useExpanded: true),
        );
      },
    );
  }

  static bool _isExpandContainer(ComponentConfig config) {
    return config.type == GenericComponentType.container &&
        config.properties['expand'] == true;
  }

  static Widget _wrapColumnChild(
    Widget child, {
    required ComponentConfig config,
    required bool useExpanded,
  }) {
    if (useExpanded && _isExpandContainer(config)) {
      return Expanded(child: child);
    }
    return child;
  }

  List<Widget> _withGap(List<Widget> children, double gap) {
    if (gap <= 0 || children.length < 2) return children;
    return [
      for (var i = 0; i < children.length; i++) ...[
        if (i > 0) SizedBox(height: gap),
        children[i],
      ],
    ];
  }
}
