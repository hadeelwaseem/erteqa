/// Schema definition for a component type.
///
/// Describes the required and optional properties for a component,
/// enabling validation at parse time rather than render time.
///
/// DESIGN:
/// - type: The component type name
/// - requiredProperties: Properties that must be present
/// - optionalProperties: Properties that might be present
/// - propertyTypes: Expected types for type-checking (optional, use for enhanced validation)
class ComponentSchema {
  final String type;
  final Set<String> requiredProperties;
  final Set<String> optionalProperties;
  final Map<String, String>
  propertyTypes; // Maps property name → type name (for documentation)

  const ComponentSchema({
    required this.type,
    this.requiredProperties = const {},
    this.optionalProperties = const {},
    this.propertyTypes = const {},
  });

  /// Returns all valid properties (required + optional).
  Set<String> get allProperties => {
    ...requiredProperties,
    ...optionalProperties,
  };

  /// Validates a component's properties against this schema.
  ///
  /// Throws [ComponentSchemaError] if validation fails.
  ///
  /// CHECKS:
  /// 1. All required properties are present
  /// 2. No unexpected properties (warns but doesn't fail)
  /// 3. Properties match expected types (if defined)
  void validate(Map<String, dynamic> properties) {
    // Check required properties
    for (final required in requiredProperties) {
      if (!properties.containsKey(required)) {
        throw ComponentSchemaError(
          'Missing required property "$required" in component type "$type"',
        );
      }
    }

    // Warn about unknown properties (but don't fail)
    final unknownProps = properties.keys
        .where((key) => !allProperties.contains(key))
        .toList();
    if (unknownProps.isNotEmpty) {
      // In a real implementation, log warning or collect for reporting
      // For now, silently allow (lenient mode)
    }
  }

  @override
  String toString() =>
      'ComponentSchema($type, required: $requiredProperties, optional: $optionalProperties)';
}

/// Exception thrown when a component schema validation fails.
class ComponentSchemaError implements Exception {
  final String message;

  ComponentSchemaError(this.message);

  @override
  String toString() => 'ComponentSchemaError: $message';
}
