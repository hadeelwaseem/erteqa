# Dynamic UI Rendering Engine - Developer Guide

**Version**: 2.0 (Phase 1 + Phase 2 Complete)  
**Last Updated**: April 2026  
**Status**: Production-Ready

---

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Adding a New Component Type](#adding-a-new-component-type)
3. [Creating Custom Renderers](#creating-custom-renderers)
4. [Using the Schema System](#using-the-schema-system)
5. [Property Parsing](#property-parsing)
6. [Testing Patterns](#testing-patterns)
7. [Best Practices](#best-practices)
8. [Troubleshooting](#troubleshooting)
9. [Migration Guides](#migration-guides)

---

## Architecture Overview

### System Components

The rendering engine consists of five layer:

```
┌─────────────────────────────────────────────────────────┐
│  JSON Config (assets/config/*.json)                     │
│  { "type": "text", "value": "Hello", ... }              │
└────────────────────┬────────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────────┐
│  Parser (AssetVariantRepository)                        │
│  - Load JSON from assets                                │
│  - Parse into ComponentConfig tree                      │
│  - Validate against ComponentSchemas                    │
└────────────────────┬────────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────────┐
│  ScreenRenderer (Enum-based Lookup)                     │
│  - text → TextRenderer                                   │
│  - image → ImageRenderer                                 │
│  - myCustom → CustomRenderer (injected)                  │
└────────────────────┬────────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────────┐
│  ScreenRenderer (Recursive Widget Builder)              │
│  - Looks up renderer from enum map                       │
│  - Calls render() method with ComponentConfig           │
│  - Rebuilds widget tree on state changes                │
└────────────────────┬────────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────────┐
│  Flutter Widgets                                        │
│  Column, Row, TextWidget, Image, Card, ...              │
└─────────────────────────────────────────────────────────┘
```

### Key Design Patterns

| Pattern | Where | Purpose |
|---------|-------|---------|
| **Strategy** | ComponentRenderer interface | Each component type implements render() |
| **Factory** | ScreenRenderer.withPrimitives() | Creates default renderer registry |
| **Registry** | ScreenRenderer | Enum-based renderer lookup |
| **Dependency Injection** | ScreenRenderer constructor | Custom renderers can be injected |
| **Visitor** | _buildComponent recursion | Traverses and transforms tree |

---

## Adding a New Component Type

### Step 1: Define the Schema (Recommended)

Define what properties your component accepts:

**File**: `lib/engine/validation/component_schemas.dart`

```dart
/// Schema: Custom button with icon and label
static const iconButton = ComponentSchema(
  type: 'iconButton',
  requiredProperties: {'label'},  // Must have this
  optionalProperties: {
    'icon',           // Icon name (e.g., 'favorite', 'settings')
    'color',          // Button color
    'onPressed',      // For future event binding
  },
  propertyTypes: {
    'label': 'string',
    'icon': 'string (icon name)',
    'color': 'string (hex)',
  },
);
```

Then add to the factory method:

```dart
static ComponentSchema? getSchema(String typeName) {
  switch (typeName) {
    // ... existing cases
    case 'iconButton':
      return iconButton;
    default:
      return null;
  }
}
```

### Step 2: Create the Renderer

**File**: `lib/engine/tree/renderers/icon_button_renderer.dart`

```dart
import 'package:flutter/material.dart';

import '../../../config/component_config.dart';
import '../../component_renderer/component_renderer.dart';
import '../parsers/property_parsers.dart';

/// Renders an IconButton component with icon and label.
///
/// JSON Properties:
/// - `label` (string, required): Button label text
/// - `icon` (string, optional): Icon name (default: 'favorite')
/// - `color` (string, optional): Button color (hex)
class IconButtonRenderer implements ComponentRenderer {
  @override
  Widget render(
    ComponentConfig config, {
    required ComponentWidgetBuilder buildChild,
    Map<String, dynamic>? dataContext,
  }) {
    final label = config.properties['label'] as String? ?? '';
    final iconName = config.properties['icon'] as String? ?? 'favorite';
    final color = PropertyParsers.parseColor(
      config.properties['color'] as String?,
    );

    // Map icon name to IconData
    final iconData = _getIconData(iconName);

    return ElevatedButton.icon(
      icon: Icon(iconData, color: color),
      label: Text(label),
      onPressed: () {
        // TODO: Wire up event binding in Phase 3
      },
    );
  }

  /// Maps icon names to Flutter IconData
  IconData _getIconData(String name) {
    switch (name) {
      case 'favorite':
        return Icons.favorite;
      case 'settings':
        return Icons.settings;
      case 'add':
        return Icons.add;
      case 'delete':
        return Icons.delete;
      // ... more icons
      default:
        return Icons.favorite;
    }
  }
}
```

### Step 3: Register with ScreenRenderer

**File**: `lib/engine/screen_renderer/screen_renderer.dart`

```dart
static Map<GenericComponentType, ComponentRenderer> _createDefaultRenderers() {
  return {
    // ... existing entries
    GenericComponentType.iconButton: IconButtonRenderer(),
  };
}
```

### Step 4: Update GenericComponentType Enum (Optional)

**File**: `lib/core/enums/generic_component_type.dart`

```dart
enum GenericComponentType {
  // ... existing
  iconButton,  // Add to enum (optional - string registry can work without it)
}
```

### Step 5: Use in JSON

```json
{
  "type": "iconButton",
  "label": "Add Item",
  "icon": "add",
  "color": "#FF5722"
}
```

### Step 6: Test It

```dart
test('IconButtonRenderer renders button with icon', () {
  final config = ComponentConfig(
    type: GenericComponentType.iconButton,
    properties: {
      'label': 'Click me',
      'icon': 'favorite',
      'color': '#FF5722',
    },
  );

  final renderer = IconButtonRenderer();
  final widget = renderer.render(config, buildChild: (_) => SizedBox());

  expect(widget, isA<ElevatedButton>());
});
```

---

## Creating Custom Renderers

### Basic Renderer Template

```dart
import 'package:flutter/material.dart';

import '../../../config/component_config.dart';
import '../../component_renderer/component_renderer.dart';
import '../parsers/property_parsers.dart';

/// [ComponentRenderer] implementation for [MyCustom] components.
///
/// Renders: MyCustom widget
/// JSON Properties:
/// - `title` (string, required): Widget title
/// - `subtitle` (string, optional): Widget subtitle
///
/// Example JSON:
/// ```json
/// {
///   "type": "myCustom",
///   "title": "Hello",
///   "subtitle": "World",
///   "child": { "type": "text", "value": "Content" }
/// }
/// ```
class MyCustomRenderer implements ComponentRenderer {
  @override
  Widget render(
    ComponentConfig config, {
    required ComponentWidgetBuilder buildChild,
    Map<String, dynamic>? dataContext,
  }) {
    // 1. Extract properties from config
    final title = config.properties['title'] as String? ?? '';
    final subtitle = config.properties['subtitle'] as String?;

    // 2. Render child if present
    final child = config.child != null ? buildChild(config.child!) : null;

    // 3. Build widget
    return Column(
      children: [
        Text(title, style: Theme.of(context).textTheme.headline6),
        if (subtitle != null) Text(subtitle),
        if (child != null) child,
      ],
    );
  }
}
```

### Advanced: Renderer with State (Cubit Integration - Phase 3)

```dart
/// Renderer that consumes Cubit state (future feature)
class CounterRenderer implements ComponentRenderer {
  @override
  Widget render(
    ComponentConfig config, {
    required ComponentWidgetBuilder buildChild,
    Map<String, dynamic>? dataContext,
  }) {
    // In Phase 3, dataContext will contain Cubit instances
    final counterCubit = dataContext?['counterCubit'] as CounterCubit?;

    if (counterCubit == null) {
      return Text('No counter cubit provided');
    }

    return BlocBuilder<CounterCubit, int>(
      bloc: counterCubit,
      builder: (context, count) {
        return Text('Count: $count');
      },
    );
  }
}
```

---

## Using the Schema System

### Schema Structure

```dart
ComponentSchema(
  type: 'myComponent',
  requiredProperties: {'title'},          // Must be present
  optionalProperties: {'subtitle', 'icon'},  // May be omitted
  propertyTypes: {
    'title': 'string',
    'subtitle': 'string',
    'icon': 'string (icon-name)',
  },
);
```

### Validation

Validation happens automatically in the parser:

```dart
// In AssetVariantRepository._parseComponentConfig()
final schema = ComponentSchemas.getSchema(typeString);
if (schema != null) {
  try {
    schema.validate(properties);
  } catch (e) {
    print('[ComponentConfig] Schema validation warning: $e');
  }
}
```

### Adding Property Type Validation

For advanced validation, extend `ComponentSchema`:

```dart
class AdvancedComponentSchema extends ComponentSchema {
  @override
  void validate(Map<String, dynamic> properties) {
    super.validate(properties);

    // Custom validation
    if (properties['width'] != null && properties['width'] is! num) {
      throw ComponentSchemaError('width must be a number');
    }

    if (properties['color'] != null) {
      final color = properties['color'] as String;
      if (!color.startsWith('#')) {
        throw ComponentSchemaError('color must be hex format (#RRGGBB)');
      }
    }
  }
}
```

---

## Property Parsing

### Available Parsers

The `PropertyParsers` class provides utilities for converting JSON values to Flutter types:

| Parser | Input | Output | Example |
|--------|-------|--------|---------|
| `parseColor()` | `"#FF5722"` | `Color` | `Color(0xFFFF5722)` |
| `parseDouble()` | `24` or `"24"` | `double?` | `24.0` |
| `parseEdgeInsets()` | `16` or `{left:10,top:5}` | `EdgeInsets?` | All four or custom |
| `parseBorderRadius()` | `12` | `BorderRadius?` | Circular 12 |
| `parseFontWeight()` | `"bold"` or `"w700"` | `FontWeight` | FontWeight.bold |
| `parseTextAlign()` | `"center"` | `TextAlign` | TextAlign.center |
| `parseMainAxisAlignment()` | `"spaceBetween"` | `MainAxisAlignment` | MainAxisAlignment.spaceBetween |
| `parseImageFitString()` | `"cover"` | `String` | Returns validated string |

### Using in Your Renderer

```dart
class MyRenderer implements ComponentRenderer {
  @override
  Widget render(ComponentConfig config, ...) {
    // Parse various property types
    final padding = PropertyParsers.parseEdgeInsets(
      config.properties['padding'],
    );
    final color = PropertyParsers.parseColor(
      config.properties['color'] as String?,
    );
    final fontSize = PropertyParsers.parseDouble(
      config.properties['fontSize'],
    );

    return Container(
      padding: padding,
      color: color,
      child: Text('Hello', style: TextStyle(fontSize: fontSize)),
    );
  }
}
```

### Creating Custom Parsers

Add to `PropertyParsers`:

```dart
static bool parseBoolean(dynamic v, {bool defaultValue = false}) {
  if (v is bool) return v;
  if (v is String) return v.toLowerCase() == 'true';
  if (v is int) return v != 0;
  return defaultValue;
}

static Offset? parseOffset(dynamic v) {
  if (v is Map) {
    return Offset(
      (v['dx'] as num?)?.toDouble() ?? 0,
      (v['dy'] as num?)?.toDouble() ?? 0,
    );
  }
  return null;
}
```

---

## Testing Patterns

### Unit Test: Component Schema

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sooq_merchant/engine/validation/component_schemas.dart';

void main() {
  group('ComponentSchemas', () {
    test('text schema requires value property', () {
      final schema = ComponentSchemas.text;

      expect(
        () => schema.validate({}),
        throwsA(isA<ComponentSchemaError>()),
      );
    });

    test('text schema accepts optional properties', () {
      final schema = ComponentSchemas.text;

      expect(
        () => schema.validate({
          'value': 'Hello',
          'fontSize': 16,
          'color': '#000000',
        }),
        returnsNormally,
      );
    });
  });
}
```

### Unit Test: Custom Renderer

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

import 'package:sooq_merchant/config/component_config.dart';
import 'package:sooq_merchant/core/enums/generic_component_type.dart';
import 'package:sooq_merchant/engine/tree/renderers/icon_button_renderer.dart';

void main() {
  group('IconButtonRenderer', () {
    test('renders ElevatedButton with icon and label', () {
      final config = ComponentConfig(
        type: GenericComponentType.button, // or custom type
        properties: {
          'label': 'Click me',
          'icon': 'favorite',
        },
      );

      final renderer = IconButtonRenderer();
      final widget = renderer.render(
        config,
        buildChild: (_) => SizedBox(),
      );

      expect(widget, isA<ElevatedButton>());
    });

    test('applies custom color when provided', () {
      final config = ComponentConfig(
        type: GenericComponentType.button,
        properties: {
          'label': 'Click me',
          'color': '#FF5722',
        },
      );

      final renderer = IconButtonRenderer();
      final widget = renderer.render(
        config,
        buildChild: (_) => SizedBox(),
      );

      // Verify color is applied (extract from widget style)
      expect(widget, isA<ElevatedButton>());
    });
  });
}
```

### Integration Test: Full Rendering Pipeline

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('VariantScreen renders dynamic config', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: VariantScreen(variantId: 'test'),
      ),
    );

    // Wait for async loading
    await tester.pumpAndSettle();

    // Verify widgets rendered
    expect(find.byType(Text), findsWidgets);
    expect(find.byType(Container), findsWidgets);
  });
}
```

### Widget Test: Mock Renderer

```dart
test('ScreenRenderer uses injected renderers', () {
  // Mock renderer
  class MockTextRenderer implements ComponentRenderer {
    @override
    Widget render(
      ComponentConfig config, {
      required ComponentWidgetBuilder buildChild,
      Map<String, dynamic>? dataContext,
    }) {
      return Text('MOCKED');
    }
  }

  final screenRenderer = ScreenRenderer({
    GenericComponentType.text: MockTextRenderer(),
  });

  final config = ScreenConfig(
    pageId: 'test',
    pageName: 'Test',
    root: ComponentConfig(
      type: GenericComponentType.text,
      properties: {'value': 'Hello'},
    ),
  );

  final widget = screenRenderer.render(config);

  expect(widget, isA<Text>());
  expect((widget as Text).data, 'MOCKED');
});
```

---

## Best Practices

### 1. Always Define Schemas

**Do**:
```dart
static const myComponent = ComponentSchema(
  type: 'myComponent',
  requiredProperties: {'title'},
  optionalProperties: {'subtitle'},
);
```

**Don't**:
```dart
// Skipping schema = harder to debug, worse error messages
class MyRenderer implements ComponentRenderer { ... }
```

### 2. Use Property Parsers

**Do**:
```dart
final color = PropertyParsers.parseColor(
  config.properties['color'] as String?,
);
```

**Don't**:
```dart
// Manual parsing = error-prone
final color = Color(int.parse(config.properties['color']));
```

### 3. Provide Sensible Defaults

**Do**:
```dart
final fontSize = PropertyParsers.parseDouble(
  config.properties['fontSize'],
) ?? 16.0;  // Default to 16
```

**Don't**:
```dart
// Crash if missing
final fontSize = (config.properties['fontSize'] as num).toDouble();
```

### 4. Extract and Validate Once

**Do**:
```dart
final label = config.properties['label'] as String? ?? '';
// Then use label multiple times
```

**Don't**:
```dart
// Extracting each time
Text(config.properties['label'] as String? ?? '')
```

### 5. Document JSON Format in Comments

**Do**:
```dart
/// JSON Properties:
/// - `label` (string, required): Button label
/// - `color` (string, optional): Hex color (default: theme primary)
/// - `size` (string, optional): "small", "medium", "large"
```

**Don't**:
```dart
// Missing docs = guesswork for integrators
```

### 6. Test Both Valid and Invalid Cases

**Do**:
```dart
test('renders with required properties only', () { ... });
test('renders with all optional properties', () { ... });
test('uses defaults for missing optional properties', () { ... });
test('schema validation catches missing required property', () { ... });
```

**Don't**:
```dart
// Only testing happy path
test('renders button', () { ... });
```

---

## Troubleshooting

### Issue: "Unknown component type: myComponent"

**Problem**: JSON references a component type that's not registered

**Solutions**:
1. Check ComponentRegistry is initialized: `ComponentRegistry.init()`
2. Verify registration: `ComponentRegistry.register('myComponent', renderer)`
3. Check spelling in JSON matches registration

**Debug**:
```dart
// Show all registered types
print(ComponentRegistry.getAll().keys);

// Check specific type
if (ComponentRegistry.isRegistered('myComponent')) {
  print('myComponent is registered');
} else {
  print('myComponent NOT registered');
}
```

### Issue: "Missing required property 'title' in component type 'myComponent'"

**Problem**: JSON is missing a required property

**Solution**: Add the required property to JSON
```json
{
  "type": "myComponent",
  "title": "My Title"  // Add this
}
```

### Issue: Renderer not rendering correctly / blank widget

**Problem**: Renderer logic has an issue

**Debugging steps**:
1. Check properties are extracted correctly:
   ```dart
   print('label: ${config.properties['label']}');
   print('color: ${config.properties['color']}');
   ```

2. Verify parsers return expected types:
   ```dart
   final color = PropertyParsers.parseColor(...);
   print('color == null? $color');
   ```

3. Check defaults are sensible:
   ```dart
   final fontSize = ... ?? 16.0;
   print('fontSize: $fontSize');
   ```

### Issue: "Undefined name 'PropertyParsers'"

**Problem**: Missing import

**Solution**: Add import
```dart
import '../parsers/property_parsers.dart';
```

### Issue: Schema validation warnings in console

**Problem**: JSON has properties that don't match schema

**Validation is lenient** - doesn't fail, just warns

**To fix**: 
1. Check JSON matches schema definition
2. Or add property to optionalProperties in schema if it's valid

---

## Migration Guides

### From Hardcoded Renderers to ComponentRegistry

**Before (Phase 1)**:
```dart
// Adding new type required editing multiple files
enum GenericComponentType {
  text,
  image,
  myCustom,  // Had to add here
}

class ScreenRenderer {
  factory ScreenRenderer.withPrimitives() {
    return ScreenRenderer({
      ...
      GenericComponentType.myCustom: MyCustomRenderer(),  // And here
    });
  }
}
```

**After (Phase 2+)**:
```dart
// Just register once
ComponentRegistry.register('myCustom', MyCustomRenderer());

// No code changes needed - just works!
```

### From Manual Validation to Schema-Based

**Before**:
```dart
// Validation happened at render time
class MyRenderer implements ComponentRenderer {
  @override
  Widget render(ComponentConfig config, ...) {
    final title = config.properties['title'] as String?;
    if (title == null) {
      // Oops, render fails or shows blank
      return SizedBox();
    }
    return Text(title);
  }
}
```

**After**:
```dart
// Define schema
static const myComponent = ComponentSchema(
  type: 'myComponent',
  requiredProperties: {'title'},
);

// Define renderer - can assume title is there
class MyRenderer implements ComponentRenderer {
  @override
  Widget render(ComponentConfig config, ...) {
    final title = config.properties['title'] as String? ?? 'Untitled';
    return Text(title);  // Safe because schema validated it
  }
}
```

### From Testing with Real Renderers to Mock Renderers

**Before**:
```dart
// Had to use real renderers in tests
testWidgets('VariantScreen renders', (tester) async {
  await tester.pumpWidget(
    MaterialApp(home: VariantScreen(variantId: 'test'))
  );
  // Slow, flaky, hard to test specific behaviors
});
```

**After**:
```dart
// Can use mock renderers
test('ScreenRenderer looks up correct renderer', () {
  class MockRenderer implements ComponentRenderer {
    @override
    Widget render(...) => Text('MOCK');
  }

  final renderer = ScreenRenderer({
    'text': MockRenderer(),
  });

  // Fast, reliable, tests specific behavior
});
```

---

## FAQ

### Q: Do I have to add an enum entry for my new component?

**A**: No. The enum is optional. The registry is string-based and works independently. Adding to the enum is a convenience for type safety in code but not required.

### Q: Can I override default renderers?

**A**: Yes. Register with the same key to override:
```dart
ComponentRegistry.register('text', CustomTextRenderer());
```

### Q: What happens if validation fails?

**A**: Currently, validation warnings are printed to console but rendering continues (lenient mode). This can be changed to strict mode in future.

### Q: Can I validate custom properties?

**A**: Yes. Extend `ComponentSchema.validate()` or create a subclass with custom logic.

### Q: Do I need to initialize ComponentRegistry?

**A**: It's optional but recommended. You can call `ComponentRegistry.init()` in main() or it will auto-initialize on first use.

### Q: How do I test a renderer with dataContext?

**A**: Pass it as a parameter:
```dart
renderer.render(
  config,
  buildChild: (_) => SizedBox(),
  dataContext: {'myCubit': myCubitInstance},
);
```

### Q: Can I use ComponentRegistry in tests?

**A**: Yes, but be careful with side effects. Consider resetting in tearDown:
```dart
tearDown(() => ComponentRegistry.reset());
```

---

## Getting Help

### Documentation Files

- **This guide**: Overview and patterns
- **ComponentRegistry**: `lib/engine/registry/component_registry.dart`
- **ComponentSchema**: `lib/engine/validation/component_schema.dart`
- **ComponentSchemas**: `lib/engine/validation/component_schemas.dart` (all schemas)
- **ScreenRenderer**: `lib/engine/screen_renderer/screen_renderer.dart`
- **Example Renderers**: `lib/engine/tree/renderers/*.dart`

### Code Examples

Look at existing renderers for reference:
- `TextRenderer` - Simple leaf widget
- `ColumnRenderer` - Multi-child layout
- `ContainerRenderer` - Single-child with styling
- `ImageRenderer` - Network image with error handling

### Contact & Questions

For questions about the rendering engine:
- Check this guide first
- Review existing renderer implementations
- Ask in code review / team chat

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 2.0 | Apr 2026 | Phase 2: Registry, Schema, DI |
| 1.0 | Apr 2026 | Phase 1: Spacer, Image renderers |

---

## Next Steps

- **Phase 3** (Month 2+): Event system and state binding
- **Phase 4** (TBD): Component marketplace/plugin system
- **Phase 5** (TBD): Visual component editor

