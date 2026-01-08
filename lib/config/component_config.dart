enum ComponentType { button, list, card }

class ComponentConfig {
  final ComponentType type;
  final Map<String, dynamic> properties;

  const ComponentConfig({required this.type, required this.properties});
}
