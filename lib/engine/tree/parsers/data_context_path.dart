/// Resolves dotted paths against the engine [dataContext] map.
///
/// JSON bindings may use either `requests.foo.data` or
/// `dataContext.requests.foo.data`; both are accepted.
dynamic resolveDataContextPath(
  Map<String, dynamic>? root,
  String? path,
) {
  if (root == null || path == null || path.isEmpty) {
    return null;
  }

  var normalized = path.trim();
  if (normalized.startsWith('dataContext.')) {
    normalized = normalized.substring('dataContext.'.length);
  }

  dynamic current = root;
  for (final segment in normalized.split('.')) {
    if (segment.isEmpty) {
      continue;
    }
    if (current is Map && current.containsKey(segment)) {
      current = current[segment];
    } else {
      return null;
    }
  }
  return current;
}

/// Resolves a network image URL from [urlPath], with item-level aliases when empty.
///
/// Grids bind `item.image`; APIs may expose `imageUrl`, `primaryImageUrl`, etc.
String? resolveBoundImageUrl(
  Map<String, dynamic>? dataContext,
  String? urlPath,
) {
  final direct = resolveDataContextPath(dataContext, urlPath);
  final directText = direct?.toString().trim() ?? '';
  if (directText.isNotEmpty) {
    return directText;
  }

  final normalized = urlPath?.trim() ?? '';
  if (!normalized.startsWith('item.')) {
    return null;
  }

  final item = resolveDataContextPath(dataContext, 'item');
  if (item is! Map) {
    return null;
  }

  const keys = <String>[
    'image',
    'imageUrl',
    'primaryImageUrl',
    'primaryThumbnailUrl',
    'thumbnailUrl',
    'publicUrl',
  ];

  for (final key in keys) {
    final value = item[key]?.toString().trim() ?? '';
    if (value.isNotEmpty) {
      return value;
    }
  }

  return null;
}
