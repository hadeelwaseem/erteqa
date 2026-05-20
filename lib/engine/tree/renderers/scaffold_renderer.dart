import 'package:flutter/material.dart';

import '../../../config/component_config.dart';
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
    final child = config.child != null ? buildChild(config.child!) : null;

    return ColoredBox(
      color: backgroundColor ?? const Color(0xFFF8FAFC),
      child: child != null
          ? Builder(
              builder: (context) {
                final h = MediaQuery.sizeOf(context).height;
                final pad = MediaQuery.paddingOf(context).vertical;
                final minHeight = (h - pad).clamp(0.0, double.infinity);
                return _ScrollableScaffoldBody(
                  minHeight: minHeight,
                  dataContext: dataContext,
                  child: child,
                );
              },
            )
          : const SizedBox.expand(),
    );
  }
}

class _ScrollableScaffoldBody extends StatelessWidget {
  const _ScrollableScaffoldBody({
    required this.minHeight,
    required this.dataContext,
    required this.child,
  });

  final double minHeight;
  final Map<String, dynamic>? dataContext;
  final Widget child;

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

  @override
  Widget build(BuildContext context) {
    final hasLoadingMore = _hasLoadingMore(dataContext);

    return SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: minHeight),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.topCenter,
              widthFactor: 1.0,
              child: child,
            ),
            if (hasLoadingMore) _buildLoadingFooter(),
          ],
        ),
      ),
    );
  }
}
