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
    if (current is Map<String, dynamic> && current.containsKey(segment)) {
      current = current[segment];
    } else {
      return null;
    }
  }
  return current;
}
