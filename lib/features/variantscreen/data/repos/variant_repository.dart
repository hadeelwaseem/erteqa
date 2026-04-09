import 'dart:convert';

import 'package:flutter/services.dart';

import '../../../../config/component_config.dart';
import '../../../../config/screen_config.dart';
import '../../../../core/enums/generic_component_type.dart';

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
  Future<ScreenConfig> loadVariant(String variantId);
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

  @override
  Future<ScreenConfig> loadVariant(String variantId) async {
    final jsonString = await rootBundle.loadString(
      '$_configPath/$variantId.json',
    );
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
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
    final rootJson = json['root'] as Map<String, dynamic>;
    final root = _parseComponentConfig(rootJson);
    return ScreenConfig(
      pageId: pageId,
      pageName:
          pageName ?? pageId, // Fallback to pageId if pageName not provided
      root: root,
    );
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
  ComponentConfig _parseComponentConfig(Map<String, dynamic> json) {
    final typeString = json['type'] as String;
    final type = GenericComponentType.values.firstWhere(
      (e) => e.name == typeString,
      orElse: () => throw ArgumentError('Unknown component type: $typeString'),
    );

    final properties = <String, dynamic>{};
    for (final entry in json.entries) {
      final key = entry.key;
      if (key != 'type' && key != 'child' && key != 'children') {
        properties[key] = entry.value;
      }
    }

    ComponentConfig? child;
    if (json['child'] != null) {
      child = _parseComponentConfig(json['child'] as Map<String, dynamic>);
    }

    List<ComponentConfig>? children;
    if (json['children'] != null) {
      final list = json['children'] as List;
      children = list
          .map((e) => _parseComponentConfig(e as Map<String, dynamic>))
          .toList();
    }

    return ComponentConfig(
      type: type,
      properties: properties,
      child: child,
      children: children,
    );
  }
}
