import 'package:flutter/material.dart';

import '../../../config/component_config.dart';
import '../../../core/enums/generic_component_type.dart';
import '../../component_renderer/component_renderer.dart';
import '../parsers/property_parsers.dart';

/// Renders the top-level page scaffold as a scrollable color-wrapped container.
///
/// NOTE: Does NOT create a Flutter [Scaffold] widget — the outer Scaffold is
/// provided by [TabShellWidget] (via ShellRoute). Creating a nested Scaffold
/// here would cause double-scaffold issues (duplicate bottom bars, etc.).
///
/// JSON props:
/// - `backgroundColor` (string, hex color) — page background
/// - `pageScroll` (string) — from pages[].scroll via VariantRepository:
///   `vertical` (default) | `none`
class ScaffoldRenderer implements ComponentRenderer {
  @override
  Widget render(
    ComponentConfig config, {
    required ComponentWidgetBuilder buildChild,
    Map<String, dynamic>? dataContext,
  }) {
    final backgroundColor = PropertyParsers.parseColor(
      config.properties['backgroundColor'] as String?,
    );
    final pageScroll = config.properties['pageScroll'] as String? ?? 'vertical';
    final child = config.child != null ? buildChild(config.child!) : null;
    final bodyHasExpand =
        config.child != null && _treeHasExpandContainer(config.child!);

    return ColoredBox(
      color: backgroundColor ?? const Color(0xFFF8FAFC),
      child: child != null
          ? Builder(
              builder: (context) {
                final h = MediaQuery.sizeOf(context).height;
                final pad = MediaQuery.paddingOf(context).vertical;
                final minHeight = (h - pad).clamp(0.0, double.infinity);
                if (pageScroll == 'none') {
                  return _StaticScaffoldBody(
                    dataContext: dataContext,
                    fillViewport: bodyHasExpand,
                    child: child,
                  );
                }
                return _ScrollableScaffoldBody(
                  minHeight: bodyHasExpand ? minHeight : null,
                  dataContext: dataContext,
                  child: child,
                );
              },
            )
          : const SizedBox.expand(),
    );
  }

  /// True when any [container] node in the subtree has `expand: true`.
  static bool _treeHasExpandContainer(ComponentConfig config) {
    if (config.type == GenericComponentType.container &&
        config.properties['expand'] == true) {
      return true;
    }
    if (config.child != null && _treeHasExpandContainer(config.child!)) {
      return true;
    }
    for (final c in config.children ?? const <ComponentConfig>[]) {
      if (_treeHasExpandContainer(c)) return true;
    }
    return false;
  }
}

bool _hasLoadingMore(Map<String, dynamic>? dataContext) {
  final loadingMoreByKey = dataContext?['loadingMoreRequests'];
  return loadingMoreByKey is Map && loadingMoreByKey.isNotEmpty;
}

Widget _buildLoadingFooter() {
  return const Padding(
    padding: EdgeInsets.only(top: 12, bottom: 20),
    child: Center(child: CircularProgressIndicator()),
  );
}

Widget _scaffoldBodyColumn({
  required Widget child,
  required Map<String, dynamic>? dataContext,
}) {
  final hasLoadingMore = _hasLoadingMore(dataContext);
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Align(alignment: Alignment.topCenter, widthFactor: 1.0, child: child),
      if (hasLoadingMore) _buildLoadingFooter(),
    ],
  );
}

class _ScrollableScaffoldBody extends StatelessWidget {
  const _ScrollableScaffoldBody({
    required this.minHeight,
    required this.dataContext,
    required this.child,
  });

  final double? minHeight;
  final Map<String, dynamic>? dataContext;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    Widget scrollChild = _scaffoldBodyColumn(
      child: child,
      dataContext: dataContext,
    );
    if (minHeight != null) {
      scrollChild = ConstrainedBox(
        constraints: BoxConstraints(minHeight: minHeight!),
        child: scrollChild,
      );
    }
    return SingleChildScrollView(child: scrollChild);
  }
}

class _StaticScaffoldBody extends StatelessWidget {
  const _StaticScaffoldBody({
    required this.dataContext,
    required this.fillViewport,
    required this.child,
  });

  final Map<String, dynamic>? dataContext;
  final bool fillViewport;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : MediaQuery.sizeOf(context).height;
        final hasLoadingMore = _hasLoadingMore(dataContext);
        final bodyChild = fillViewport
            ? Expanded(child: child)
            : child;
        return SizedBox(
          width: double.infinity,
          height: height,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              bodyChild,
              if (hasLoadingMore) _buildLoadingFooter(),
            ],
          ),
        );
      },
    );
  }
}
