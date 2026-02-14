import 'package:sooq_merchant/core/enums/component_type.dart';

class ComponentConfig {
  final ComponentType type;
  final Map<String, dynamic> properties;

  const ComponentConfig({required this.type, required this.properties});
}
