# Rendering Engine - Architecture & Design Decisions

Detailed explanation of architectural choices, trade-offs, and design decisions.

---

## Table of Contents

1. [System Architecture](#system-architecture)
2. [Design Decisions](#design-decisions)
3. [Trade-offs](#trade-offs)
4. [Future Improvements](#future-improvements)
5. [Comparison with Alternatives](#comparison-with-alternatives)

---

## System Architecture

### High-Level Overview

```
Input Layer (JSON Configs)
    ↓
    ├─ assets/config/config.json
    ├─ assets/config/classic.json
    └─ assets/config/modern.json
    
    ↓
    
Parse Layer (AssetVariantRepository)
  ├─ Load JSON from assets
  ├─ Parse simple or builder JSON
  ├─ Normalize props/style into ComponentConfig
  ├─ Validate structure + types against GenericComponentType.values
  ├─ Validate against ComponentSchemas (property-level)
  └─ Emit warnings on invalid properties
    
    ↓
    
Renderer Map (ScreenRenderer)
  ├─ Enum-based lookup (GenericComponentType → Renderer)
  ├─ Default map with 14 built-in renderers
  ├─ Optional injection for overrides
  └─ Unsupported type fallback
    
    ↓
    
Rendering Layer (ScreenRenderer)
    ├─ Recursive widget builder
    ├─ Dependency injection ready
    ├─ Delegates to specialized renderers
    └─ Supports custom renderer injection
    
    ↓
    
Strategy Layer (Renderer Implementations)
    ├─ TextRenderer
    ├─ ButtonRenderer
    ├─ ImageRenderer
    ├─ LayoutRenderers (Column, Row, Container)
    └─ Custom renderers (injected)
    
    ↓
    
Output Layer (Flutter Widgets)
    └─ Running UI
```

### Component Responsibilities

| Layer | Responsibility | Extensibility |
|-------|---------------|----|
| **Input** | Define UI structure in JSON | Add JSON configs |
| **Parse** | Convert JSON to ComponentConfig tree | Modify parser for new properties |
| **Registry** | Map component types to renderers | Register new types |
| **Render** | Build widget tree recursively | Inject custom renderers |
| **Strategy** | Implement specific widget rendering | Create new renderers |
| **Output** | Display Flutter widgets | Use built-in Flutter capabilities |

---

## Design Decisions

### Decision 1: Parser-Driven Architecture

**What**: Configuration parsing is the first step, not the last

**Why**:
- ✅ Catches errors early (typos, missing properties)
- ✅ Enables validation reports
- ✅ Clearer error messages with context
- ✅ Foundation for configuration versioning

**Alternative Rejected**:
- Render-time parsing: Harder to debug, UI shows blank instead of error

**Code Location**: `lib/features/variantscreen/data/repos/variant_repository.dart`

---

### Decision 2: Renderer Map (Enum-Based)

**What**: Component lookup uses enum keys in ScreenRenderer

**Why**:
- ✅ Clear mapping between JSON type strings and renderers
- ✅ Easier validation with known component set
- ✅ Simple default wiring for production
- ✅ Single authoritative component taxonomy via `GenericComponentType`

**Example**:
```dart
final renderer = ScreenRenderer.withPrimitives();
```

**Alternative Deferred**:
- String registry (ComponentRegistry) exists but is not the active path

**Code Location**: `lib/engine/screen_renderer/screen_renderer.dart`

---

### Decision 3: Lenient Validation by Default

**What**: Schema violations warn but don't fail parsing; structural/type validation is strict

**Why**:
- ✅ Better developer experience during iteration
- ✅ Graceful degradation if config has typos
- ✅ Can be switched to strict mode later
- ✅ Allows phased rollout of new properties
 - ✅ Structural/type errors fail fast with explicit path errors

**Example**:
```dart
// JSON has typo
{ "type": "text", "fonSize": 16 }  // Note: typo

// Result: Warning printed, still renders with default fontSize
```

**Alternative Rejected**:
- Strict validation: Would fail every config with any typo

**Switchable To**:
```dart
// Future option
schema.validate(properties, strict: true);  // Throw on error
```

**Code Location**: `lib/features/variantscreen/data/repos/variant_repository.dart`

---

### Decision 4: Dependency Injection in ScreenRenderer

**What**: Renderer instances can be injected instead of hard-coded

**Why**:
- ✅ Enables testing with mock renderers
- ✅ Supports custom renderer chains
- ✅ No changes needed to existing code
- ✅ Foundation for plugin systems

**Example**:
```dart
// Production
ScreenRenderer.withPrimitives()

// Testing
ScreenRenderer({
  'text': MockTextRenderer(),  // Override for tests
})
```

**Alternative Rejected**:
- Service locator: Less explicit, harder to test
- Singleton: Hard to override for tests

**Code Location**: `lib/engine/screen_renderer/screen_renderer.dart`

---

### Decision 5: ComponentSchema for Metadata

**What**: Each component type has a schema defining its properties

**Why**:
- ✅ Single source of truth for "what's valid"
- ✅ Enables better IDE support (future)
- ✅ Foundation for documentation generation
- ✅ Validation happens early in parsing
- ✅ Schema itself is testable

**Example**:
```dart
static const text = ComponentSchema(
  type: 'text',
  requiredProperties: {'value'},      // Must have
  optionalProperties: {'fontSize'},   // Nice to have
  propertyTypes: {'value': 'string'}, // Type hint
);
```

**Alternative Rejected**:
- No schema: Would need validation in each renderer (duplicated)
- XML schema: Harder to maintain in Dart code

**Code Location**: `lib/engine/validation/component_schemas.dart`

---

### Decision 6: Recursive Widget Building with Callbacks

**What**: ScreenRenderer uses recursive `_buildComponent()` with `buildChild` callbacks

**Why**:
- ✅ Clean separation of concerns (each renderer focuses on own widget)
- ✅ Natural representation of UI tree structure
- ✅ Easy to understand and maintain
- ✅ Enables lazy building if needed (future optimization)

**How It Works**:
```dart
// ScreenRenderer._buildComponent()
Widget _buildComponent(ComponentConfig config) {
  final renderer = _renderers[config.type];
  
  return renderer.render(
    config,
    buildChild: (childConfig) => _buildComponent(childConfig),
  );
}

// Each renderer calls buildChild for its children
class ColumnRenderer implements ComponentRenderer {
  Widget render(ComponentConfig config, ComponentWidgetBuilder buildChild, ...) {
    final children = config.children
        .map((c) => buildChild(c))  // Recursively build
        .toList();
    return Column(children: children);
  }
}
```

**Alternative Rejected**:
- Direct widget construction: Less flexible
- Visitor pattern with side effects: Harder to test

**Code Location**: `lib/engine/screen_renderer/screen_renderer.dart`

---

## Trade-offs

### Trade-off 1: String-Based vs Type-Safe

**Choice**: String-based registry (sacrificed type safety for flexibility)

**What We Gained**:
- Runtime registration of custom types
- No need to recompile for new components
- Plugin-style component loading possibility

**What We Lost**:
- IDE type hints for component names
- Compile-time verification of type names

**Mitigation**:
- Schema definitions provide documentation
- Runtime checks: `ComponentRegistry.isRegistered('text')`
- Test coverage validates registration

---

### Trade-off 2: Lenient vs Strict Validation

**Choice**: Lenient validation (sacrificed error-catching for UX)

**What We Gained**:
- Better developer experience
- Faster iteration
- Graceful degradation

**What We Lost**:
- Early detection of all config issues
- Stricter data quality

**Mitigation**:
- Warnings printed to console
- Schema system in place to switch to strict mode
- Test coverage can enforce strict validation

**Future Option**:
```dart
// Could add strict mode later
final renderer = ScreenRenderer.withPrimitives(strict: true);
```

---

### Trade-off 3: Single Registry vs Multiple Registries

**Choice**: Single global registry (simpler, sacrificed isolation)

**What We Gained**:
- Simple API
- Centralized configuration
- Easy to inspect all types

**What We Lost**:
- Isolation between test cases (if not careful with tearDown)
- Need for explicit reset in tests

**Mitigation**:
```dart
tearDown(() => ComponentRegistry.reset());  // Clean up after tests
```

---

### Trade-off 4: Schema in Code vs External Schema Files

**Choice**: Schema definitions in Dart code (sacrificed flexibility for maintainability)

**What We Gained**:
- Easy to review in code
- Type-safe schema definitions
- Clear diff history
- No file parsing needed

**What We Lost**:
- Dynamic schema loading
- Non-developers can't modify schema

**Future Alternative**:
```dart
// Could load schemas from JSON later
final schemas = loadSchemasFromAsset('schemas.json');
```

---

## Future Improvements

### Phase 3: Event & Action System

**Current State**: Buttons have empty `onPressed: () {}`

**Future**:
```dart
// JSON with event binding
{
  "type": "button",
  "label": "Save",
  "onPressed": {
    "action": "emit",
    "cubit": "formCubit",
    "event": "submit"
  }
}
```

**Implementation Approach**:
1. Define ActionType enum
2. Create Action and ActionDispatcher classes
3. Extend parser to recognize action definitions
4. Wire button renderer to dispatch actions

---

### Phase 3: State Binding (Cubit Interpolation)

**Current State**: All text is static strings

**Future**:
```dart
// JSON with Cubit binding
{
  "type": "text",
  "value": "${@TokenCubit.token}"  // Reference Cubit state
}
```

**Implementation Approach**:
1. Define interpolation syntax
2. Create interpolation resolver
3. Pass Cubits through dataContext
4. Resolve at render time

---

### Multiple Registries (Environments)

**Future**:
```dart
// Different registries for different environments
final devRegistry = ComponentRegistry.create();
devRegistry.register('debug', DebugViewRenderer());

final ScreenRenderer renderer = ScreenRenderer(devRegistry.getAll());
```

---

### Schema Validation Report Generation

**Future**:
```dart
// Generate validation report for all configs
final report = ValidationReportGenerator.generateForAllConfigs();
print(report);
// Output:
// ✓ config.json: valid
// ✓ classic.json: valid
// ✗ modern.json: 3 issues
//   - Line 24: Unknown property "shadow"
//   - Line 45: Missing required property "url"
```

---

### Component Metadata & Discovery

**Future**:
```dart
// Inspect component capabilities
final metadata = ComponentRegistry.getMetadata('text');
print(metadata.supportedProperties);
print(metadata.requiredProperties);
print(metadata.examples);
```

---

### IDE Integration & Auto-Complete

**Future**: VS Code extension that provides:
- Auto-complete for component types
- Property validation while typing
- Schema hints
- Live preview of JSON config

---

## Comparison with Alternatives

### Alternative 1: Fully Declarative UI (No Code)

**Example**: Pure JSON, no Dart renderer classes

```json
{
  "type": "myCustom",
  "config": {
    "title": "Hello",
    "child": { "type": "text" }
  }
}
```

**Pros**:
- Non-developers can define UI
- Easy to serialize/deserialize

**Cons**:
- Limited to predefined UI capabilities
- Can't express complex logic
- Harder to test
- **Chosen**: Hybrid approach instead

---

### Alternative 2: Template-Based (Hxml/JSX Style)

**Example**: HTML-like templates

```html
<column>
  <text>Hello</text>
  <button>Click</button>
</column>
```

**Pros**:
- Familiar to web developers
- Visual structure clear

**Cons**:
- Need parser for templating language
- Less direct mapping to Flutter
- **Chosen**: JSON for structured data instead

---

### Alternative 3: NoCode Visual Builder

**Example**: Drag-and-drop UI editor

**Pros**:
- Easiest for non-developers
- Real-time preview

**Cons**:
- Complex tool to build
- Hard to version control
- Overkill for current needs
- **Chosen**: Text-based JSON for version control instead

---

### Our Approach: Hybrid

**What We Keep**:
- ✅ Type-safe Dart code for renderers (testable, maintainable)
- ✅ JSON configs for structure (easy to version, review, diff)
- ✅ Schemas for validation (catches errors early)
- ✅ Registry pattern (extensible, plugin-ready)

**Result**: Best of both worlds
- Developers: Full control via Dart renderers
- Designers/Config Editors: Easy JSON structure
- Teams: Clear version history, easy review
- Users: Type-safe testing, fast performance

---

## Design Principles

### Principle 1: Separation of Concerns

Each layer has one job:
- **JSON**: Structure
- **Parser**: Validation
- **Registry**: Mapping
- **Renderer**: Rendering
- **Widgets**: Display

### Principle 2: Extensibility Without Breaking Changes

New features added without modifying existing code:
- New component type: Register with `ComponentRegistry.register()`
- New property: Add to schema, parse in renderer
- New behavior: Create custom renderer, inject

### Principle 3: Testability

Every layer is independently testable:
- Schemas: `test('schema validation', ...)`
- Renderers: `test('MySender renders correctly', ...)`
- Registry: `test('registry lookup', ...)`
- Integration: `testWidgets('full pipeline', ...)`

### Principle 4: Fail Gracefully

Errors don't crash the app:
- Unknown component type: Renders `SizedBox.shrink()`
- Missing optional property: Uses default value
- Schema violation: Warns but continues

---

## Performance Considerations

### JSON Parsing

- **Current**: Synchronous (acceptable for moderate configs)
- **Future**: Could parallelize if configs grow very large
- **Optimization**: Parsing happens once at startup

### Component Lookup

- **Current**: HashMap lookup (O(1))
- **Performance**: Negligible overhead vs direct instantiation

### Widget Building

- **Current**: Recursive tree traversal (matches UI structure)
- **Performance**: Same as any tree-based UI framework

### Memory

- **Current**: Registry holds renderer instances
- **Overhead**: ~5KB for 9 renderers
- **Scaling**: Linear with number of component types

---

## Security Considerations

### URL Validation (Images)

**Current**: URLs not validated

**Future Consideration**:
- Validate URLs against allowlist for network images
- Check file paths for asset/file images

### JSON Injection

**Not Applicable**: JSON comes from app assets, not user input

### Type Safety

**Current**: Dynamic properties map

**Future**: Could add type validation in property parsers

---

## Backward Compatibility

### Phase 1 → Phase 2 Upgrade

- ✅ All Phase 1 code still works
- ✅ Config.json, classic.json, modern.json render unchanged
- ✅ No migrations required
- ✅ New features are opt-in

### Phase 2 → Phase 3 Upgrade

- ✅ Planned to be backward compatible
- ✅ New event/state binding features optional
- ✅ Existing static configs continue working

---

## Conclusion

The rendering engine is designed for:
- **Maintainability**: Clear separation of concerns
- **Extensibility**: New types without code changes
- **Testability**: Each layer independently testable
- **Robustness**: Graceful failure modes
- **Performance**: Minimal overhead

The hybrid approach (JSON configs + Dart renderers) balances:
- Developer productivity (full control via code)
- Designer friendliness (easy JSON structure)
- Version control (clean git diffs)
- Type safety (Dart compile-time checks)

