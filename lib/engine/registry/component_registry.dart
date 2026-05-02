import '../component_renderer/component_renderer.dart';
import '../tree/renderers/button_renderer.dart';
import '../tree/renderers/card_renderer.dart';
import '../tree/renderers/column_renderer.dart';
import '../tree/renderers/container_renderer.dart';
import '../tree/renderers/image_renderer.dart';
import '../tree/renderers/row_renderer.dart';
import '../tree/renderers/scaffold_renderer.dart';
import '../tree/renderers/spacer_renderer.dart';
import '../tree/renderers/text_renderer.dart';

/// Registry for dynamically mapping component types to their renderers.
///
/// This enables:
/// - Adding new component types without modifying core code
/// - Runtime registration of custom renderers
/// - Easier testing with mock/stub renderers
/// - Centralized component metadata
///
/// DESIGN APPROACH:
/// Uses string-based mapping (type name → renderer) rather than enum-based.
/// This decouples the registry from the enum definition and allows:
/// 1. Optional enum entries (render without being in enum)
/// 2. Gradual migration to new rendering systems
/// 3. Plugin-style component registration
///
/// USAGE:
/// ```dart
/// // Initialize with default renderers
/// ComponentRegistry.init();
///
/// // Register a custom renderer
/// ComponentRegistry.register('myCustomType', MyCustomRenderer());
///
/// // Look up a renderer
/// final renderer = ComponentRegistry.get('text');
///
/// // Get all renderers
/// final all = ComponentRegistry.getAll();
/// ```
class ComponentRegistry {
  static late final Map<String, ComponentRenderer> _registry;
  static bool _initialized = false;

  ComponentRegistry._();

  /// Initializes the registry with default renderers.
  ///
  /// Call this once during app startup, typically in main() or in a service initialization layer.
  /// Must be called before rendering any dynamic UI.
  ///
  /// If called multiple times, resets the registry to defaults (clears any custom registrations).
  static void init() {
    _registry = _createDefaultRegistry();
    _initialized = true;
  }

  /// Registers a new component renderer (or overrides an existing one).
  ///
  /// [typeName]: The component type name as used in JSON (e.g., "text", "myCustom")
  /// [renderer]: The ComponentRenderer implementation
  ///
  /// Throws [StateError] if registry not initialized.
  ///
  /// EXAMPLE:
  /// ```dart
  /// ComponentRegistry.register('customButton', CustomButtonRenderer());
  /// ```
  static void register(String typeName, ComponentRenderer renderer) {
    _ensureInitialized();
    _registry[typeName] = renderer;
  }

  /// Retrieves a renderer by component type name.
  ///
  /// Returns null if type is not registered (don't throw - allows graceful degradation).
  ///
  /// [typeName]: The component type name as used in JSON
  ///
  /// EXAMPLE:
  /// ```dart
  /// final renderer = ComponentRegistry.get('text');
  /// if (renderer == null) {
  ///   // Handle unknown type
  /// }
  /// ```
  static ComponentRenderer? get(String typeName) {
    _ensureInitialized();
    return _registry[typeName];
  }

  /// Retrieves all registered renderers.
  ///
  /// Useful for:
  /// - Inspecting available component types
  /// - Cloning/overriding the registry
  /// - Validation and documentation
  ///
  /// Returns a copy to prevent accidental mutations.
  static Map<String, ComponentRenderer> getAll() {
    _ensureInitialized();
    return Map.unmodifiable(_registry);
  }

  /// Checks if a component type is registered.
  static bool isRegistered(String typeName) {
    _ensureInitialized();
    return _registry.containsKey(typeName);
  }

  /// Checks if the registry has been initialized.
  static bool get isInitialized => _initialized;

  /// Resets the registry to defaults (clears all custom registrations).
  ///
  /// Useful for testing or in apps that support dynamic component reloading.
  static void reset() {
    init();
  }

  /// Ensures registry is initialized, throwing if not.
  static void _ensureInitialized() {
    if (!_initialized) {
      throw StateError(
        'ComponentRegistry not initialized. Call ComponentRegistry.init() '
        'during app startup before rendering any UI.',
      );
    }
  }

  /// Creates the default component registry.
  ///
  /// DESIGN NOTE:
  /// This maps component type names (strings) to renderers, decoupling from the enum.
  /// If an enum value is added but not registered here, it will fail gracefully (return null)
  /// rather than crashing, allowing for staged rollout of new types.
  static Map<String, ComponentRenderer> _createDefaultRegistry() {
    return {
      // Layout components
      'scaffold': ScaffoldRenderer(),
      'column': ColumnRenderer(),
      'row': RowRenderer(),
      'container': ContainerRenderer(),

      // Leaf components
      'text': TextRenderer(),
      'button': ButtonRenderer(),
      'image': ImageRenderer(),

      // Material components
      'card': CardRenderer(),

      // Spacer (flexible spacing)
      'spacer': SpacerRenderer(),
    };
  }
}
