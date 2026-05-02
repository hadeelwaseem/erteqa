# Rendering Engine - API Reference

Quick lookup guide for the most commonly used classes and methods.

---

## ComponentRegistry API

Static registry for runtime component type lookup and registration.

### Initialization

```dart
ComponentRegistry.init()
```

Initialize the registry with default renderers. Call once during app startup.

**Example**:
```dart
void main() {
  ComponentRegistry.init();
  runApp(MyApp());
}
```

---

### Registration

```dart
ComponentRegistry.register(String typeName, ComponentRenderer renderer)
```

Register (or override) a renderer for a component type.

**Parameters**:
- `typeName` (String): Component type name as used in JSON (e.g., "text", "myCustom")
- `renderer` (ComponentRenderer): The renderer implementation

**Throws**: `StateError` if registry not initialized

**Example**:
```dart
ComponentRegistry.register('iconButton', IconButtonRenderer());
ComponentRegistry.register('text', CustomTextRenderer());  // Override
```

---

### Lookup

```dart
ComponentRenderer? ComponentRegistry.get(String typeName)
```

Look up a renderer by component type name.

**Parameters**:
- `typeName` (String): Component type to look up

**Returns**: `ComponentRenderer?` or null if not registered

**Example**:
```dart
final renderer = ComponentRegistry.get('text');
if (renderer != null) {
  final widget = renderer.render(config);
}
```

---

### Inspection

```dart
Map<String, ComponentRenderer> ComponentRegistry.getAll()
bool ComponentRegistry.isRegistered(String typeName)
bool ComponentRegistry.get isInitialized
```

Get all renderers, check if type is registered, or check initialization status.

**Example**:
```dart
// List all registered types
print(ComponentRegistry.getAll().keys);  // ['text', 'button', 'image', ...]

// Check if type exists
if (ComponentRegistry.isRegistered('myCustom')) {
  print('myCustom renderer available');
}

// Verify initialized
assert(ComponentRegistry.isInitialized, 'Must call ComponentRegistry.init()');
```

---

### Reset

```dart
void ComponentRegistry.reset()
```

Reset registry to defaults (clears all custom registrations).

**Example**:
```dart
// In test tearDown
tearDown(() => ComponentRegistry.reset());
```

---

## ScreenRenderer API

Recursive widget builder that renders `ScreenConfig` trees.

### Constructor

```dart
ScreenRenderer(Map<GenericComponentType, ComponentRenderer> renderers)
```

Create renderer with custom registry.

**Parameters**:
- `renderers`: Map of component types to renderer implementations

**Example**:
```dart
// Use custom renderers
final renderer = ScreenRenderer({
  GenericComponentType.text: CustomTextRenderer(),
  GenericComponentType.button: CustomButtonRenderer(),
});
```

---

### Factory Constructor

```dart
factory ScreenRenderer.withPrimitives()
```

Create renderer with all default (9) renderers pre-wired.

**Example**:
```dart
final renderer = ScreenRenderer.withPrimitives();
```

---

### Rendering

```dart
Widget render(ScreenConfig config, {Map<String, dynamic>? dataContext})
```

Render a screen configuration into a widget tree.

**Parameters**:
- `config` (ScreenConfig): Screen configuration
- `dataContext` (Map?): Optional context data (for phase 3 state binding)

**Returns**: Widget tree

**Example**:
```dart
final widget = renderer.render(screenConfig);

// With data context (Phase 3)
final widget = renderer.render(
  screenConfig,
  dataContext: {'tokenCubit': tokenCubit},
);
```

---

## ComponentSchema API

Metadata and validation for component types.

### Constructor

```dart
const ComponentSchema({
  required String type,
  Set<String> requiredProperties = const {},
  Set<String> optionalProperties = const {},
  Map<String, String> propertyTypes = const {},
})
```

Define a component schema.

**Parameters**:
- `type`: Component type name
- `requiredProperties`: Properties that must be present
- `optionalProperties`: Properties that may be present
- `propertyTypes`: Type hints (for documentation)

**Example**:
```dart
const textSchema = ComponentSchema(
  type: 'text',
  requiredProperties: {'value'},
  optionalProperties: {'fontSize', 'color', 'fontWeight'},
  propertyTypes: {
    'value': 'string',
    'fontSize': 'number',
    'color': 'string (hex)',
  },
);
```

---

### Validation

```dart
void validate(Map<String, dynamic> properties)
```

Validate component properties against schema.

**Parameters**:
- `properties`: Properties to validate

**Throws**: `ComponentSchemaError` if validation fails

**Example**:
```dart
try {
  schema.validate({'value': 'Hello'});
} on ComponentSchemaError catch (e) {
  print('Validation failed: $e');
}
```

---

### Property Inspection

```dart
Set<String> get allProperties
```

Get all valid properties (required + optional).

**Example**:
```dart
final valid = schema.allProperties;  // {'value', 'fontSize', 'color', ...}
```

---

## ComponentSchemas API

Centralized schema definitions for all component types.

### Schema Accessors

```dart
static const ComponentSchema scaffold     // Scaffold wrapper
static const ComponentSchema column       // Vertical layout
static const ComponentSchema row          // Horizontal layout
static const ComponentSchema container    // Box with padding
static const ComponentSchema text         // Text widget
static const ComponentSchema button       // Button widget
static const ComponentSchema card         // Material card
static const ComponentSchema spacer       // Flexible spacer
static const ComponentSchema image        // Image widget
```

**Example**:
```dart
final textSchema = ComponentSchemas.text;
print(textSchema.requiredProperties);  // {'value'}
```

---

### Schema Lookup

```dart
static ComponentSchema? getSchema(String typeName)
static Map<String, ComponentSchema> getAll()
```

Look up schemas by name or get all schemas.

**Example**:
```dart
// Look up by name
final schema = ComponentSchemas.getSchema('text');
if (schema != null) {
  schema.validate(properties);
}

// Get all schemas
final allSchemas = ComponentSchemas.getAll();
print(allSchemas.keys);  // ['container', 'scaffold', 'column', ...]
```

---

## PropertyParsers API

Utility methods for converting JSON values to Flutter types.

### Color Parsing

```dart
static Color? parseColor(String? hex)
```

Parse hex string to Color.

**Example**:
```dart
final color = PropertyParsers.parseColor('#FF5722');  // Color(0xFFFF5722)
```

---

### Dimension Parsing

```dart
static double? parseDouble(dynamic v)
```

Parse number or string to double.

**Example**:
```dart
final fontSize = PropertyParsers.parseDouble(16);      // 16.0
final size = PropertyParsers.parseDouble('24.5');      // 24.5
final none = PropertyParsers.parseDouble(null);        // null
```

---

### EdgeInsets Parsing

```dart
static EdgeInsets? parseEdgeInsets(dynamic v)
```

Parse number or object to EdgeInsets.

**Example**:
```dart
// Uniform
final p1 = PropertyParsers.parseEdgeInsets(16);
// Result: EdgeInsets.all(16)

// Custom
final p2 = PropertyParsers.parseEdgeInsets({
  'top': 10,
  'left': 5,
  'right': 5,
  'bottom': 10,
});
```

---

### BorderRadius Parsing

```dart
static BorderRadius? parseBorderRadius(dynamic v)
```

Parse number to BorderRadius.

**Example**:
```dart
final radius = PropertyParsers.parseBorderRadius(12);
// Result: BorderRadius.circular(12)
```

---

### FontWeight Parsing

```dart
static FontWeight parseFontWeight(String? v)
```

Parse string to FontWeight enum.

**Example**:
```dart
PropertyParsers.parseFontWeight('bold')     // FontWeight.bold
PropertyParsers.parseFontWeight('w700')     // FontWeight.w700
PropertyParsers.parseFontWeight('normal')   // FontWeight.normal
PropertyParsers.parseFontWeight('invalid')  // FontWeight.normal (default)
```

---

### TextAlign Parsing

```dart
static TextAlign parseTextAlign(String? v)
```

Parse string to TextAlign enum.

**Example**:
```dart
PropertyParsers.parseTextAlign('center')    // TextAlign.center
PropertyParsers.parseTextAlign('left')      // TextAlign.left
PropertyParsers.parseTextAlign('justify')   // TextAlign.justify
```

---

### Alignment Parsing

```dart
static MainAxisAlignment parseMainAxisAlignment(String? v)
static CrossAxisAlignment parseCrossAxisAlignment(String? v)
static AlignmentGeometry? parseAlignment(String? v)
```

Parse alignment strings.

**Example**:
```dart
PropertyParsers.parseMainAxisAlignment('spaceBetween')
// Result: MainAxisAlignment.spaceBetween

PropertyParsers.parseCrossAxisAlignment('stretch')
// Result: CrossAxisAlignment.stretch

PropertyParsers.parseAlignment('topLeft')
// Result: Alignment.topLeft
```

---

### Image Properties

```dart
static String parseImageFitString(String? v)
static String parseImageSource(String? v)
```

Parse image fit and source type.

**Example**:
```dart
PropertyParsers.parseImageFitString('cover')      // 'cover'
PropertyParsers.parseImageFitString('contain')    // 'contain'
PropertyParsers.parseImageFitString('invalid')    // 'cover' (default)

PropertyParsers.parseImageSource('network')  // 'network'
PropertyParsers.parseImageSource('asset')    // 'asset'
PropertyParsers.parseImageSource('invalid')  // 'network' (default)
```

---

## ComponentRenderer Interface

Base interface for all component renderers.

### Method

```dart
Widget render(
  ComponentConfig config, {
  required ComponentWidgetBuilder buildChild,
  Map<String, dynamic>? dataContext,
})
```

Render a component to a Widget.

**Parameters**:
- `config` (ComponentConfig): Component configuration
- `buildChild` (Function): Build function for child components
- `dataContext` (Map?): Optional state context

**Returns**: Widget

**Example**:
```dart
class MyRenderer implements ComponentRenderer {
  @override
  Widget render(
    ComponentConfig config, {
    required ComponentWidgetBuilder buildChild,
    Map<String, dynamic>? dataContext,
  }) {
    final label = config.properties['label'] as String? ?? '';
    
    return Container(
      child: Text(label),
    );
  }
}
```

---

## Data Models

### ComponentConfig

Configuration node for a UI component.

```dart
class ComponentConfig {
  final GenericComponentType type;
  final Map<String, dynamic> properties;
  final ComponentConfig? child;
  final List<ComponentConfig>? children;
}
```

### ScreenConfig

Top-level screen configuration.

```dart
class ScreenConfig {
  final String pageId;
  final String pageName;
  final ComponentConfig root;
}
```

---

## Error Types

### ComponentSchemaError

Thrown when schema validation fails.

```dart
class ComponentSchemaError implements Exception {
  final String message;
}
```

**Example**:
```dart
try {
  schema.validate({});
} on ComponentSchemaError catch (e) {
  print('Error: ${e.message}');
}
```

---

## Enums

### GenericComponentType

Supported component types (9 total).

```dart
enum GenericComponentType {
  scaffold,
  column,
  row,
  container,
  text,
  button,
  card,
  spacer,
  image,
}
```

---

## Quick Reference: Common Tasks

### Add a New Component Type

1. Define schema (optional but recommended)
2. Create renderer class
3. Register with ComponentRegistry

```dart
// 1. Schema
const myComponent = ComponentSchema(
  type: 'myComponent',
  requiredProperties: {'title'},
);

// 2. Renderer
class MyComponentRenderer implements ComponentRenderer {
  @override
  Widget render(...) { ... }
}

// 3. Register
ComponentRegistry.register('myComponent', MyComponentRenderer());
```

### Use in JSON

```json
{
  "type": "myComponent",
  "title": "Hello"
}
```

---

### Test a Renderer

```dart
test('MyComponentRenderer renders title', () {
  final config = ComponentConfig(
    type: GenericComponentType.text, // or custom type
    properties: {'title': 'Test'},
  );

  final renderer = MyComponentRenderer();
  final widget = renderer.render(config, buildChild: (_) => SizedBox());

  expect(widget, isA<Container>());
});
```

---

### Mock a Renderer in Tests

```dart
final renderer = ScreenRenderer({
  GenericComponentType.text: MockTextRenderer(),
});
```

---

## See Also

- **Main Guide**: `docs/RENDERING_ENGINE_GUIDE.md`
- **Source Files**:
  - `lib/engine/registry/component_registry.dart`
  - `lib/engine/validation/component_schema.dart`
  - `lib/engine/screen_renderer/screen_renderer.dart`
  - `lib/engine/tree/parsers/property_parsers.dart`

