import '../core/enums/generic_component_type.dart';

/// Tree-based configuration for a UI component.
/// Each node may have a single [child] (scaffold, container, card) or
/// multiple [children] (column, row), or be a leaf (text, button).
class ComponentConfig {
  final GenericComponentType type;
  final Map<String, dynamic> properties;
  final ComponentConfig? child;
  final List<ComponentConfig>? children;

  const ComponentConfig({
    required this.type,
    this.properties = const {},
    this.child,
    this.children,
  });
}
