import 'dart:convert';

import 'package:flutter/services.dart';

import '../../../../config/component_config.dart';
import '../../../../config/screen_config.dart';
import '../../../../core/enums/generic_component_type.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../engine/validation/component_schemas.dart';

/// Abstract repository for loading dynamic screen configurations.
///
/// **Responsibility**: Load and parse [ScreenConfig] from a data source.
///
/// **Current implementation**: [AssetVariantRepository] loads from JSON files in assets.
/// Future implementations could load from backend, database, etc.
abstract class VariantRepository {
  /// Load screen config by pageId.
  ///
  /// **Parameters**:
  /// - [variantId]: The pageId (e.g., 'classic', 'dashboard', 'modern')
  ///
  /// **Returns**: Fully parsed [ScreenConfig] with pageId, pageName, and root component tree.
  ///
  /// **Throws**: Exception if config cannot be found or parsed.
  /// Error is caught by [VariantCubit] and emitted as [VariantFailure].
  Future<ScreenConfig> loadVariant(String variantId, {String? pageRoute});
}

/// Loads screen configs from JSON asset files.
///
/// **Pattern**: Deterministic, stateless loading from `assets/config/{pageId}.json`
///
/// **File naming**: pageId directly maps to filename (e.g., pageId='classic' → 'classic.json')
///
/// **Parsing**:
/// - Extracts pageId from JSON `id` field (required)
/// - Extracts pageName from JSON `pageName` field (optional; fallback to pageId)
/// - Recursively parses root component tree from JSON `root` field
/// - Returns fully-formed [ScreenConfig]
///
/// **Config format** (JSON):
/// ```json
/// {
///   "id": "pageId",
///   "pageName": "Display Name",
///   "root": {
///     "type": "scaffold",
///     "backgroundColor": "#FFFFFF",
///     "child": { ... }
///   }
/// }
/// ```
class AssetVariantRepository implements VariantRepository {
  static const _configPath = 'assets/config';
  static final Set<String> _allowedTypes = GenericComponentType.values
      .where((type) => type != GenericComponentType.unsupported)
      .map((type) => type.name)
      .toSet();

  @override
  Future<ScreenConfig> loadVariant(
    String variantId, {
    String? pageRoute,
  }) async {
    final jsonString = await rootBundle.loadString(
      '$_configPath/$variantId.json',
    );
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    if (json['pages'] is List) {
      return _parseBuilderScreenConfig(json, variantId, pageRoute: pageRoute);
    }
    return _parseScreenConfig(json);
  }

  /// Parses JSON into [ScreenConfig] with all required fields.
  ///
  /// **Fields extracted**:
  /// - `id`: Required; becomes [ScreenConfig.pageId]
  /// - `pageName`: Optional; becomes [ScreenConfig.pageName] (fallback: use id)
  /// - `root`: Required; becomes [ScreenConfig.root] (recursively parsed)
  ScreenConfig _parseScreenConfig(Map<String, dynamic> json) {
    final pageId = json['id'] as String;
    final pageName = json['pageName'] as String?;
    final rootJson = json['root'];
    if (rootJson is! Map<String, dynamic>) {
      throw ArgumentError('root must be an Object at root');
    }
    _validateComponentJson(rootJson, path: 'root');
    final root = _parseComponentConfig(rootJson, path: 'root');
    return ScreenConfig(
      pageId: pageId,
      pageName:
          pageName ?? pageId, // Fallback to pageId if pageName not provided
      root: root,
    );
  }

  ScreenConfig _parseBuilderScreenConfig(
    Map<String, dynamic> json,
    String variantId, {
    String? pageRoute,
  }) {
    final pages = (json['pages'] as List)
        .whereType<Map<String, dynamic>>()
        .toList(growable: false);
    if (pages.isEmpty) {
      throw ArgumentError('Builder config has no pages.');
    }

    final initialRoute =
        (json['navigation'] as Map<String, dynamic>?)?['initialRoute']
            as String?;
    final routeToLoad = pageRoute ?? initialRoute;
    final selectedPage = pages.firstWhere(
      (page) => page['route'] == routeToLoad || page['id'] == routeToLoad,
      orElse: () => pages.first,
    );

    final body = <ComponentConfig>[];
    final rawBody = selectedPage['body'] as List?;
    if (selectedPage.containsKey('body') && rawBody == null) {
      throw ArgumentError(
        'children must be a List at pages[${pages.indexOf(selectedPage)}].body',
      );
    }
    if (rawBody != null) {
      for (var i = 0; i < rawBody.length; i++) {
        final entry = rawBody[i];
        if (entry is! Map<String, dynamic>) {
          throw ArgumentError(
            'children must contain objects at pages[${pages.indexOf(selectedPage)}].body[$i]',
          );
        }
        _validateComponentJson(
          entry,
          path: 'pages[${pages.indexOf(selectedPage)}].body[$i]',
        );
        body.add(
          _parseBuilderComponentConfig(
            entry,
            path: 'pages[${pages.indexOf(selectedPage)}].body[$i]',
          ),
        );
      }
    }
    if (selectedPage.containsKey('appBar') &&
        selectedPage['appBar'] is! Map<String, dynamic>) {
      throw ArgumentError(
        'child must be an Object at pages[${pages.indexOf(selectedPage)}].appBar',
      );
    }
    final appBar = selectedPage['appBar'] is Map<String, dynamic>
        ? () {
            final appBarJson = selectedPage['appBar'] as Map<String, dynamic>;
            _validateComponentJson(
              appBarJson,
              path: 'pages[${pages.indexOf(selectedPage)}].appBar',
            );
            return _parseBuilderComponentConfig(
              appBarJson,
              path: 'pages[${pages.indexOf(selectedPage)}].appBar',
            );
          }()
        : null;
    final children = <ComponentConfig>[if (appBar != null) appBar, ...body];

    final root = ComponentConfig(
      type: GenericComponentType.scaffold,
      properties: {
        if (selectedPage['background'] is String)
          'backgroundColor': selectedPage['background'],
      },
      child: ComponentConfig(
        type: GenericComponentType.column,
        properties: const {'crossAxisAlignment': 'stretch'},
        children: children,
      ),
    );

    final pageId = selectedPage['id'] as String? ?? variantId;
    final pageName =
        selectedPage['title'] as String? ??
        (json['app'] as Map<String, dynamic>?)?['name'] as String? ??
        pageId;

    return ScreenConfig(pageId: variantId, pageName: pageName, root: root);
  }

  ComponentConfig _parseBuilderComponentConfig(
    Map<String, dynamic> json, {
    required String path,
  }) {
    final rawType = json['type'] as String?;
    if (rawType == null || rawType.isEmpty) {
      throw ArgumentError('Missing type at $path');
    }
    final type = _componentTypeFromString(rawType);
    AppLogger.debug('[VariantRepository] parse node type=$rawType path=$path');
    final properties = _normalizeBuilderProperties(json, rawType);

    ComponentConfig? child;
    if (json['child'] is Map<String, dynamic>) {
      child = _parseBuilderComponentConfig(
        json['child'] as Map<String, dynamic>,
        path: '$path.child',
      );
    }

    List<ComponentConfig>? children;
    if (json['children'] is List) {
      children = (json['children'] as List).asMap().entries.map((entry) {
        final value = entry.value;
        if (value is! Map<String, dynamic>) {
          throw ArgumentError(
            'children must contain objects at $path.children[${entry.key}]',
          );
        }
        return _parseBuilderComponentConfig(
          value,
          path: '$path.children[${entry.key}]',
        );
      }).toList();
    }

    return ComponentConfig(
      type: type,
      properties: properties,
      child: child,
      children: children,
    );
  }

  Map<String, dynamic> _normalizeBuilderProperties(
    Map<String, dynamic> json,
    String rawType,
  ) {
    final properties = <String, dynamic>{'id': json['id'], 'rawType': rawType}
      ..removeWhere((_, value) => value == null);

    final props = json['props'];
    if (props is Map<String, dynamic>) {
      properties.addAll(props);
    }

    final style = json['style'];
    if (style is Map<String, dynamic>) {
      if (style.containsKey('padding')) {
        properties['padding'] = style['padding'];
      }
      if (style.containsKey('margin')) properties['margin'] = style['margin'];
      if (style.containsKey('borderRadius')) {
        properties['borderRadius'] = style['borderRadius'];
      }
      if (style['background'] is String) {
        properties['color'] = style['background'];
      }
      if (style['color'] is String) {
        properties['color'] = style['color'];
      }
      if (style.containsKey('width')) properties['width'] = style['width'];
      if (style.containsKey('height')) properties['height'] = style['height'];
    }

    if (json['data'] is Map<String, dynamic>) {
      properties['data'] = json['data'];
    }
    if (json['tap'] is Map<String, dynamic>) {
      properties['tap'] = json['tap'];
    }

    if (properties['crossAxis'] != null) {
      properties['crossAxisAlignment'] = properties['crossAxis'];
    }
    if (properties['mainAxis'] != null) {
      properties['mainAxisAlignment'] = properties['mainAxis'];
    }
    if (properties['align'] != null) {
      properties['textAlign'] = properties['align'];
    }
    if (rawType == 'spacer' && properties['size'] != null) {
      properties['height'] = properties['size'];
    }

    return properties;
  }

  /// Recursively parses component JSON into [ComponentConfig] tree.
  ///
  /// **Fields extracted**:
  /// - `type`: Component type enum (required)
  /// - `properties`: All fields except type, child, children (arbitrary key-value pairs)
  /// - `child`: Single child component (optional; for containers, scaffolds, etc.)
  /// - `children`: Multiple child components (optional; for rows, columns, etc.)
  ///
  /// **Recursion**: Child and children are recursively parsed into [ComponentConfig] trees.
  ComponentConfig _parseComponentConfig(
    Map<String, dynamic> json, {
    required String path,
  }) {
    final typeString = json['type'] as String?;
    if (typeString == null || typeString.isEmpty) {
      throw ArgumentError('Missing type at $path');
    }
    final type = _componentTypeFromString(typeString);
    AppLogger.debug(
      '[VariantRepository] parse node type=$typeString path=$path',
    );

    final properties = <String, dynamic>{};
    for (final entry in json.entries) {
      final key = entry.key;
      if (key != 'type' && key != 'child' && key != 'children') {
        properties[key] = entry.value;
      }
    }

    // Validate properties against schema (if schema exists)
    final schema = ComponentSchemas.getSchema(typeString);
    if (schema != null) {
      try {
        schema.validate(properties);
      } catch (e) {
        // Log warning but don't fail - lenient parsing
        // In production, consider strict mode: throw;
        AppLogger.debug('[ComponentConfig] Schema validation warning: $e');
      }
    }

    ComponentConfig? child;
    if (json['child'] != null) {
      child = _parseComponentConfig(
        json['child'] as Map<String, dynamic>,
        path: '$path.child',
      );
    }

    List<ComponentConfig>? children;
    if (json['children'] != null) {
      final list = json['children'] as List;
      children = list
          .asMap()
          .entries
          .map(
            (entry) => _parseComponentConfig(
              entry.value as Map<String, dynamic>,
              path: '$path.children[${entry.key}]',
            ),
          )
          .toList();
    }

    return ComponentConfig(
      type: type,
      properties: properties,
      child: child,
      children: children,
    );
  }

  GenericComponentType _componentTypeFromString(
    String typeString, {
    bool strict = true,
  }) {
    for (final type in GenericComponentType.values) {
      if (type.name == typeString) return type;
    }
    if (!strict) return GenericComponentType.unsupported;
    throw ArgumentError('Unknown component type: $typeString');
  }

  void _validateComponentJson(
    Map<String, dynamic> json, {
    required String path,
  }) {
    final rawType = json['type'] as String?;
    if (rawType == null || rawType.isEmpty) {
      throw ArgumentError('Missing type at $path');
    }

    if (!_allowedTypes.contains(rawType)) {
      throw ArgumentError('Unsupported component type: $rawType at $path');
    }

    if (json.containsKey('child') && json.containsKey('children')) {
      throw ArgumentError(
        'Node cannot contain both child and children at $path',
      );
    }

    if (json.containsKey('children')) {
      final children = json['children'];
      if (children is! List) {
        throw ArgumentError('children must be a List at $path.children');
      }
      for (var i = 0; i < children.length; i++) {
        final entry = children[i];
        if (entry is! Map<String, dynamic>) {
          throw ArgumentError(
            'children must contain objects at $path.children[$i]',
          );
        }
        _validateComponentJson(entry, path: '$path.children[$i]');
      }
    }

    if (json.containsKey('child')) {
      final child = json['child'];
      if (child is! Map<String, dynamic>) {
        throw ArgumentError('child must be an Object at $path.child');
      }
      _validateComponentJson(child, path: '$path.child');
    }
  }
}
