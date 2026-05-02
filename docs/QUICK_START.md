# Rendering Engine - Quick Start Guide

Get up and running in 5 minutes.

---

## 30-Second Overview

The rendering engine converts JSON configs into Flutter widgets:

```
JSON (assets/config/config.json)
  ↓
Parser (extract & validate)
  ↓ 
ComponentRegistry (lookup renderer)
  ↓
ScreenRenderer (build widget tree)
  ↓
Flutter UI
```

---

## Quick Reference

| Task | Code |
|------|------|
| **Initialize** | `ComponentRegistry.init()` in main() |
| **Render screen** | `ScreenRenderer.withPrimitives().render(config)` |
| **Add component type** | See "Add New Component" below |
| **Test renderer** | See "Test Renderer" below |
| **Look up renderer** | `ComponentRegistry.get('typeName')` |
| **List all types** | `ComponentRegistry.getAll().keys` |

---

## Add a New Component Type (5 Steps)

### Step 1: Create Renderer File

**File**: `lib/engine/tree/renderers/my_custom_renderer.dart`

```dart
import 'package:flutter/material.dart';
import '../../../config/component_config.dart';
import '../../component_renderer/component_renderer.dart';
import '../parsers/property_parsers.dart';

class MyCustomRenderer implements ComponentRenderer {
  @override
  Widget render(
    ComponentConfig config, {
    required ComponentWidgetBuilder buildChild,
    Map<String, dynamic>? dataContext,
  }) {
    final title = config.properties['title'] as String? ?? '';
    return Container(
      padding: EdgeInsets.all(16),
      child: Text(title),
    );
  }
}
```

### Step 2: Add Schema (Optional)

**File**: `lib/engine/validation/component_schemas.dart`

Add after existing schemas:

```dart
static const myCustom = ComponentSchema(
  type: 'myCustom',
  requiredProperties: {'title'},
  optionalProperties: {},
);
```

Add to `getSchema()` method:

```dart
case 'myCustom':
  return myCustom;
```

### Step 3: Add to Enum (Optional)

**File**: `lib/core/enums/generic_component_type.dart`

```dart
enum GenericComponentType {
  // ... existing
  myCustom,
}
```

### Step 4: Register

**File**: `lib/engine/registry/component_registry.dart`

Add to `_createDefaultRegistry()`:

```dart
'myCustom': MyCustomRenderer(),
```

### Step 5: Use in JSON

```json
{
  "type": "myCustom",
  "title": "Hello World"
}
```

Done! ✅

---

## Test a Renderer (2 Steps)

### Step 1: Write Test

**File**: `test/renderers/my_custom_renderer_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:sooq_merchant/config/component_config.dart';
import 'package:sooq_merchant/core/enums/generic_component_type.dart';
import 'package:sooq_merchant/engine/tree/renderers/my_custom_renderer.dart';

void main() {
  test('MyCustomRenderer renders title', () {
    final config = ComponentConfig(
      type: GenericComponentType.myCustom,
      properties: {'title': 'Test Title'},
    );

    final renderer = MyCustomRenderer();
    final widget = renderer.render(
      config,
      buildChild: (_) => SizedBox(),
    );

    expect(widget, isA<Container>());
  });
}
```

### Step 2: Run

```bash
flutter test test/renderers/my_custom_renderer_test.dart
```

---

## Common Patterns

### Pattern 1: Extract & Use Properties

```dart
// Safe extraction with defaults
final title = config.properties['title'] as String? ?? 'Untitled';
final color = PropertyParsers.parseColor(
  config.properties['color'] as String?,
);

// Use in widget
return Text(
  title,
  style: TextStyle(color: color),
);
```

### Pattern 2: Handle Single Child

```dart
// Render child if present
final child = config.child != null ? buildChild(config.child!) : null;

return Column(
  children: [
    Text('Header'),
    if (child != null) child,
  ],
);
```

### Pattern 3: Handle Multiple Children

```dart
// Render all children
final children = (config.children ?? [])
    .map((c) => buildChild(c))
    .toList();

return Column(
  children: children,
);
```

### Pattern 4: Apply Styling

```dart
final padding = PropertyParsers.parseEdgeInsets(
  config.properties['padding'],
) ?? EdgeInsets.all(8);

final borderRadius = PropertyParsers.parseBorderRadius(
  config.properties['borderRadius'],
);

return Container(
  padding: padding,
  decoration: BoxDecoration(
    borderRadius: borderRadius ?? BorderRadius.circular(8),
  ),
);
```

---

## Property Parsers Cheat Sheet

```dart
/// Color from hex
final color = PropertyParsers.parseColor('#FF5722');

/// Number
final size = PropertyParsers.parseDouble(24) ?? 16.0;

/// Spacing (uniform or custom)
final padding = PropertyParsers.parseEdgeInsets(16);
// or
final padding = PropertyParsers.parseEdgeInsets({
  'left': 10,
  'top': 10,
});

/// Rounded corners
final radius = PropertyParsers.parseBorderRadius(12);

/// Font styling
final weight = PropertyParsers.parseFontWeight('bold');
final align = PropertyParsers.parseTextAlign('center');

/// Alignment (layout)
final main = PropertyParsers.parseMainAxisAlignment('spaceBetween');
final cross = PropertyParsers.parseCrossAxisAlignment('center');
```

---

## Schema Definition Cheat Sheet

```dart
// Define schema for your component
static const myComponent = ComponentSchema(
  type: 'myComponent',
  
  // Properties that MUST be in JSON
  requiredProperties: {'title'},
  
  // Properties that MIGHT be in JSON
  optionalProperties: {'subtitle', 'color', 'icon'},
  
  // Type hints (for documentation)
  propertyTypes: {
    'title': 'string',
    'subtitle': 'string',
    'color': 'string (hex)',
    'icon': 'string (icon-name)',
  },
);
```

---

## Debugging

### Show All Registered Components

```dart
print(ComponentRegistry.getAll().keys);
// Prints: ['text', 'button', 'image', 'myCustom', ...]
```

### Check if Component is Registered

```dart
if (ComponentRegistry.isRegistered('myCustom')) {
  print('✓ myCustom is registered');
} else {
  print('✗ myCustom NOT registered - did you call ComponentRegistry.init()?');
}
```

### Check Schema for Component

```dart
final schema = ComponentSchemas.getSchema('text');
print('Required: ${schema?.requiredProperties}');
print('Optional: ${schema?.optionalProperties}');
```

### Validate JSON Properties

```dart
try {
  ComponentSchemas.text.validate({
    'value': 'Hello',
    'fontSize': 16,
  });
  print('✓ Properties valid');
} catch (e) {
  print('✗ Validation failed: $e');
}
```

---

## Troubleshooting

| Error | Solution |
|-------|----------|
| "Unknown component type" | Register with ComponentRegistry.register() |
| "Missing required property" | Add required property to JSON |
| Widget rendering blank | Check property extraction with print() |
| "Undefined name 'PropertyParsers'" | Add import: `import '../parsers/property_parsers.dart';` |
| Test not finding widget | Verify renderer.render() returns expected type |

---

## Next Steps

- Read [Main Developer Guide](RENDERING_ENGINE_GUIDE.md) for details
- Check [API Reference](API_REFERENCE.md) for all methods
- Look at existing renderers: `lib/engine/tree/renderers/`
- Review tests: `test/engines/tree/renderers/`

---

## Files Structure

```
lib/
├── engine/
│   ├── registry/
│   │   └── component_registry.dart          ← Register components
│   ├── validation/
│   │   ├── component_schema.dart            ← Schema base class
│   │   └── component_schemas.dart           ← All schema definitions
│   ├── screen_renderer/
│   │   └── screen_renderer.dart             ← Main renderer
│   ├── component_renderer/
│   │   └── component_renderer.dart          ← Renderer interface
│   └── tree/
│       ├── renderers/
│       │   ├── text_renderer.dart           ← Example renderers
│       │   ├── button_renderer.dart
│       │   ├── image_renderer.dart
│       │   └── ...
│       └── parsers/
│           └── property_parsers.dart        ← Utility parsers
```

---

## Template: Copy-Paste Your Renderer

```dart
import 'package:flutter/material.dart';

import '../../../config/component_config.dart';
import '../../component_renderer/component_renderer.dart';
import '../parsers/property_parsers.dart';

/// Renderer for [YourComponent].
class YourComponentRenderer implements ComponentRenderer {
  @override
  Widget render(
    ComponentConfig config, {
    required ComponentWidgetBuilder buildChild,
    Map<String, dynamic>? dataContext,
  }) {
    // Extract properties
    final title = config.properties['title'] as String? ?? '';
    final child = config.child != null ? buildChild(config.child!) : null;

    // Build widget
    return Container(
      child: Column(
        children: [
          Text(title),
          if (child != null) child,
        ],
      ),
    );
  }
}
```

---

## That's It! 🎉

You now know enough to:
- ✅ Add a new component type (5 steps)
- ✅ Create a renderer
- ✅ Use schemas
- ✅ Test your code
- ✅ Debug problems

For more details, read the [Main Developer Guide](RENDERING_ENGINE_GUIDE.md).

