import 'dart:convert';

import 'package:flutter/services.dart';

import '../../../../config/component_config.dart';
import '../../../../config/screen_config.dart';
import '../../../../core/enums/generic_component_type.dart';

abstract class VariantRepository {
  Future<ScreenConfig> loadVariant(String variantId);
}

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

  ScreenConfig _parseScreenConfig(Map<String, dynamic> json) {
    final id = json['id'] as String;
    final rootJson = json['root'] as Map<String, dynamic>;
    final root = _parseComponentConfig(rootJson);
    return ScreenConfig(id: id, root: root);
  }

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
