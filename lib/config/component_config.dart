import '../core/enums/generic_component_type.dart';

/// Defines how list/grid items should be repeated.
class ItemBuilderConfig {
  final String? source;
  final List<dynamic>? staticItems;
  final ComponentConfig? item;

  const ItemBuilderConfig({this.source, this.staticItems, this.item});
}

/// Tree-based configuration for a UI component.
/// Each node may have a single [child] (scaffold, container, card) or
/// multiple [children] (column, row), or be a leaf (text, button).
class ComponentConfig {
  final GenericComponentType type;
  final Map<String, dynamic> properties;
  final ComponentConfig? child;
  final List<ComponentConfig>? children;
  final ItemBuilderConfig? itemBuilder;
  final String? axis;
  final String? scrollDirection;
  final int? crossAxisCount;
  final double? mainAxisSpacing;
  final double? crossAxisSpacing;
  final Map<String, dynamic>? dataContextOverride;

  const ComponentConfig({
    required this.type,
    this.properties = const {},
    this.child,
    this.children,
    this.itemBuilder,
    this.axis,
    this.scrollDirection,
    this.crossAxisCount,
    this.mainAxisSpacing,
    this.crossAxisSpacing,
    this.dataContextOverride,
  });
}
