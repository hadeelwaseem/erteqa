import '../../config/component_config.dart';

/// Engine-owned placeholder rows for request-bound list/grid skeleton loading.
class SkeletonItemFactory {
  SkeletonItemFactory._();

  /// Runtime flag in [dataContext] — descendants skip network images, etc.
  static const String skeletonModeKey = 'skeletonMode';

  static const int maxItemCount = 12;

  static bool isSkeletonMode(Map<String, dynamic>? dataContext) =>
      dataContext?[skeletonModeKey] == true;

  /// Resolves how many fake rows to render while a request is loading.
  static int resolveCount({
    required Map<String, dynamic> props,
    int? crossAxisCount,
    bool isGrid = false,
    bool isHorizontal = false,
  }) {
    final fromData = _sizeFromPropsData(props);
    if (fromData != null) {
      return fromData.clamp(1, maxItemCount);
    }

    if (isGrid) {
      final cols = crossAxisCount ?? 2;
      return (cols * 2).clamp(1, maxItemCount);
    }
    if (isHorizontal) {
      return 4;
    }
    return 6;
  }

  static int? _sizeFromPropsData(Map<String, dynamic> props) {
    final data = props['data'];
    if (data is! Map) {
      return null;
    }
    final size = (data['size'] as num?)?.toInt();
    if (size != null && size > 0) {
      return size;
    }
    final requestUrl = data['requestUrl'];
    if (requestUrl is String && requestUrl.isNotEmpty) {
      final uri = Uri.tryParse(requestUrl);
      final sizeParam = int.tryParse(uri?.queryParameters['size'] ?? '');
      if (sizeParam != null && sizeParam > 0) {
        return sizeParam;
      }
    }
    return null;
  }

  static List<Map<String, dynamic>> items(int count) {
    return List.generate(count, itemAt);
  }

  /// Generic commerce-shaped map for common `valuePath` / `urlPath` bindings.
  static Map<String, dynamic> itemAt(int index) {
    return {
      'id': 'skeleton-$index',
      'name': 'Product name',
      'title': 'Product name',
      'price': '0.00',
      'image': '',
      'imageUrl': '',
      'primaryImageUrl': '',
      'slug': 'skeleton-item',
    };
  }

  /// Placeholder object for request-bound detail [container] shells.
  static Map<String, dynamic> detailPayload() {
    return {
      'name': 'Product name',
      'title': 'Product name',
      'displayPrice': '99.00',
      'description':
          'Description placeholder text for skeleton layout shaping.',
      'primaryImageUrl': '',
      'image': '',
      'imageUrl': '',
      'images': List<Map<String, dynamic>>.generate(
        4,
        (_) => {'publicUrl': '', 'image': ''},
      ),
      'inventory': {'stockStatus': 'In stock'},
    };
  }

  /// [dataContext] for detail containers: fake `requests.{key}` + [skeletonModeKey].
  static Map<String, dynamic> detailRequestContext(
    Map<String, dynamic>? base,
    String requestKey,
  ) {
    final existing = base?['requests'];
    final requests = existing is Map
        ? Map<String, dynamic>.from(existing)
        : <String, dynamic>{};
    requests[requestKey] = {
      'success': true,
      'data': detailPayload(),
    };
    return {
      ...?base,
      skeletonModeKey: true,
      'requests': requests,
    };
  }

  /// Attaches [context] as [ComponentConfig.dataContextOverride] on [config].
  static ComponentConfig withContextOverride(
    ComponentConfig config,
    Map<String, dynamic> context,
  ) {
    return ComponentConfig(
      type: config.type,
      properties: config.properties,
      child: config.child,
      children: config.children,
      itemBuilder: config.itemBuilder,
      axis: config.axis,
      scrollDirection: config.scrollDirection,
      crossAxisCount: config.crossAxisCount,
      mainAxisSpacing: config.mainAxisSpacing,
      crossAxisSpacing: config.crossAxisSpacing,
      dataContextOverride: context,
    );
  }
}
