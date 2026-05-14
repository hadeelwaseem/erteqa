import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../config/component_config.dart';
import '../../../config/screen_config.dart';
import '../../../features/product/data/models/product_list_response.dart';
import '../../../features/product/presentation/manager/product_cubit/product_cubit.dart';
import '../../component_renderer/component_renderer.dart';
import '../../requests/request_mapper.dart';
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
                  child: child,
                  config: config,
                  dataContext: dataContext,
                );
              },
            )
          : const SizedBox.expand(),
    );
  }
}

class _ScrollableScaffoldBody extends StatefulWidget {
  const _ScrollableScaffoldBody({
    required this.minHeight,
    required this.child,
    required this.config,
    required this.dataContext,
  });

  final double minHeight;
  final Widget child;
  final ComponentConfig config;
  final Map<String, dynamic>? dataContext;

  @override
  State<_ScrollableScaffoldBody> createState() =>
      _ScrollableScaffoldBodyState();
}

class _ScrollableScaffoldBodyState extends State<_ScrollableScaffoldBody> {
  static const double _prefetchExtentAfter = 240.0;

  final ScrollController _controller = ScrollController();
  final Set<String> _pendingLoadMoreKeys = <String>{};
  List<EngineMappedRequest> _requests = <EngineMappedRequest>[];

  @override
  void initState() {
    super.initState();
    _controller.addListener(_handleScroll);
    _refreshRequests();
    _scheduleCheck();
  }

  @override
  void didUpdateWidget(covariant _ScrollableScaffoldBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.config != widget.config) {
      _refreshRequests();
    }
    _scheduleCheck();
  }

  @override
  void dispose() {
    _controller.removeListener(_handleScroll);
    _controller.dispose();
    super.dispose();
  }

  void _refreshRequests() {
    _requests = EngineRequestMapper.collectRequests(
      ScreenConfig(
        pageId: 'scaffold',
        pageName: 'scaffold',
        root: widget.config,
      ),
    );
  }

  void _scheduleCheck() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _maybeLoadMore();
    });
  }

  void _handleScroll() {
    _maybeLoadMore();
  }

  void _maybeLoadMore() {
    if (!_controller.hasClients) return;

    final position = _controller.position;
    final shouldPrefetch =
        position.extentAfter <= _prefetchExtentAfter ||
        position.maxScrollExtent == 0.0;
    if (!shouldPrefetch) return;

    final dataContext = widget.dataContext;
    final requestsByKey = dataContext?['requests'];
    final loadingMoreByKey = dataContext?['loadingMoreRequests'];
    if (requestsByKey is! Map<String, dynamic>) return;

    for (final request in _requests) {
      final rawResponse = requestsByKey[request.key];
      if (rawResponse is! Map<String, dynamic>) continue;

      final response = ProductListResponse.fromJson(rawResponse);
      if (_pendingLoadMoreKeys.contains(request.key) &&
          (loadingMoreByKey is! Map<String, dynamic> ||
              loadingMoreByKey[request.key] != true)) {
        _pendingLoadMoreKeys.remove(request.key);
      }

      if (!response.meta.hasNext || response.meta.last) continue;
      if (loadingMoreByKey is Map<String, dynamic> &&
          loadingMoreByKey[request.key] == true) {
        continue;
      }
      if (_pendingLoadMoreKeys.contains(request.key)) continue;

      _pendingLoadMoreKeys.add(request.key);
      context.read<ProductCubit>().loadNextPage(
        response,
        requestKey: request.key,
      );
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

  @override
  Widget build(BuildContext context) {
    final hasLoadingMore = _hasLoadingMore(widget.dataContext);

    return SingleChildScrollView(
      controller: _controller,
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: widget.minHeight),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(child: widget.child),
            if (hasLoadingMore) _buildLoadingFooter(),
          ],
        ),
      ),
    );
  }
}
