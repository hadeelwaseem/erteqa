# SOOQ Merchant Engine - Current State Full Documentation

Version: 1.0 (current implementation)
Date: 2026-04-19
Scope: Documents the engine as it works now in code, including inputs, full process, and outputs.

---

## 1) Engine Purpose

This engine renders runtime UI pages from JSON config files.

Instead of hardcoding each page widget tree, the app loads a JSON file, parses it into a typed component tree, and recursively renders Flutter widgets.

Primary runtime flow today:
- route -> pageId
- pageId -> JSON asset file
- JSON -> ScreenConfig + ComponentConfig tree
- tree -> Flutter widget tree

---

## 2) Active Engine Surface (What Is Used Now)

### 2.1 Core Runtime Files

- `lib/core/utils/app_router.dart`
  - Defines dynamic route `/variant/:id`.
  - Resolves `id` and opens `VariantScreen`.

- `lib/features/variantscreen/presentation/views/variant_screen.dart`
  - Hosts one dynamic page instance.
  - Creates `VariantCubit` and renders loading/success/failure UI.

- `lib/features/variantscreen/presentation/manager/variant_cubit/variant_cubit.dart`
  - Loads config by variant/page id.
  - Emits `VariantLoading`, `VariantSuccess`, or `VariantFailure`.

- `lib/features/variantscreen/data/repos/variant_repository.dart`
  - `AssetVariantRepository` loads JSON from `assets/config/{variantId}.json`.
  - Parses JSON into `ScreenConfig` and recursive `ComponentConfig` nodes.
  - Validates structure + types against `GenericComponentType.values` (strict).
  - Validates properties with schema catalog (lenient mode).

- `lib/config/screen_config.dart`
  - Top-level screen contract: `pageId`, `pageName`, `root`.

- `lib/config/component_config.dart`
  - Tree node contract: `type`, `properties`, `child`, `children`.

- `lib/core/enums/generic_component_type.dart`
  - Supported enum types: `scaffold`, `column`, `row`, `container`, `text`, `button`, `card`, `spacer`, `image`, `appBar`, `divider`, `icon`, `richtext`, `unsupported`.

- `lib/engine/screen_renderer/screen_renderer.dart`
  - Recursive renderer orchestrator.
  - Maps each enum type to a concrete renderer.

- `lib/engine/component_renderer/component_renderer.dart`
  - Renderer interface used by every component renderer.

- `lib/engine/tree/renderers/*.dart`
  - Concrete rendering logic per component type.

- `lib/engine/tree/parsers/property_parsers.dart`
  - Shared conversion helpers from dynamic JSON values to Flutter types.

- `lib/engine/validation/component_schema.dart`
- `lib/engine/validation/component_schemas.dart`
  - Schema definitions + required/optional property validation.

### 2.2 Active Input Configs

Currently reachable from home menu:
- `assets/config/classic.json`
- `assets/config/modern.json`
- `assets/config/experimental.json`

Also loadable if route is called directly:
- `assets/config/dashboard.json` (different/legacy structure; see section 10)
- any other `assets/config/{id}.json` if file exists and matches parser contract

---

## 3) Engine Inputs

Engine input has three levels:

1. Navigation input
- `variantId` from route path `/variant/:id`

2. Data source input
- JSON file at `assets/config/{variantId}.json`

3. Rendering input
- Parsed `ScreenConfig` with recursive `ComponentConfig` tree

### 3.1 Navigation Input Contract

- Route: `/variant/:id`
- Path param: `id` (string)
- Fallback in router: if missing, defaults to `classic`

### 3.2 Screen JSON Contract (Top Level)

Expected by `AssetVariantRepository._parseScreenConfig`:

```json
{
  "id": "classic",
  "pageName": "Classic Dashboard",
  "root": {
    "type": "scaffold",
    "backgroundColor": "#FFFFFF",
    "child": { "...": "..." }
  }
}
```

Required top-level fields:
- `id` (string)
- `root` (object)

Optional top-level fields:
- `pageName` (string, fallback to `id`)

### 3.3 Component Node Contract

Every node must include:
- `type` (string enum name)

May include:
- arbitrary properties (all keys except `type`, `child`, `children`)
- `child` (single component object)
- `children` (array of component objects)

Parser behavior:
- Validates structure and type against `GenericComponentType.values`
- Throws with explicit path on missing/unsupported types or invalid child shape
- Converts type string to `GenericComponentType`
- Recursively parses `child` and `children`

### 3.4 Property Types Input Rules

Parsing helpers accept these forms:

- color: hex string like `#RRGGBB` (parsed to `Color`)
- number: `num` (and in some helpers, numeric string)
- edgeInsets:
  - single number -> `EdgeInsets.all(n)`
  - object `{left, top, right, bottom}` -> `EdgeInsets.only(...)`
- borderRadius: number -> `BorderRadius.circular(n)`
- alignments and enum-like values: string keywords

Invalid values usually do not throw at parse helper level; they fall back to null/default behavior.

### 3.5 Data Context Input (Prepared, Not Used)

- `ScreenRenderer.render` accepts optional `dataContext`.
- `ComponentRenderer.render` also accepts optional `dataContext`.
- Current built-in renderers do not consume it yet.

---

## 4) Full Processing Pipeline (End-to-End)

This is the exact runtime process today.

### Stage 0: App Bootstrap

1. `main.dart` calls `setupServiceLocator()`.
2. DI registers `VariantRepository` as `AssetVariantRepository`.
3. Router is created via `AppRouter.setupRouter(...)`.

### Stage 1: Trigger

1. User taps a variant in Home screen, or app navigates directly.
2. App navigates to `/variant/{variantId}`.

### Stage 2: Route Resolution

1. Router extracts `id` from path params.
2. Router creates `VariantScreen(variantId, variantRepository)`.

### Stage 3: State Boot

1. `VariantScreen` creates `VariantCubit(variantRepository, variantId)`.
2. `VariantCubit` constructor immediately calls `loadVariant()`.
3. Cubit emits `VariantLoading`.

### Stage 4: JSON Load + Parse

1. Repository loads `assets/config/{variantId}.json` with `rootBundle.loadString`.
2. Decodes JSON to `Map<String, dynamic>`.
3. Parses top-level into `ScreenConfig`:
   - `pageId` from `id`
   - `pageName` from `pageName` or fallback to `id`
   - `root` from recursive component parse

### Stage 5: Recursive Component Parse

For each component JSON node:

1. Validate node structure and type using `GenericComponentType.values`.
2. Read `type` string.
3. Convert to enum `GenericComponentType`.
4. Build `properties` map from all keys except `type/child/children`.
5. Lookup schema in `ComponentSchemas`.
6. Validate properties:
  - missing required property -> schema error thrown in validator
  - repository catches and logs warning, continues (lenient mode)
7. Recursively parse `child` and `children` if present.
8. Return `ComponentConfig` node.

### Stage 6: State Output

1. On success, cubit emits `VariantSuccess(screenConfig)`.
2. On failure (file missing, bad type, malformed structure), cubit emits `VariantFailure(message)`.

### Stage 7: Render Orchestration

When `VariantSuccess` is received:

1. `VariantScreen` calls `ScreenRenderer.withPrimitives().render(config)`.
2. `ScreenRenderer` initializes default map of 9 renderers.
3. `_buildComponent` starts from `config.root`.
4. For each node:
   - find renderer by enum type
   - if renderer missing -> `SizedBox.shrink()`
   - else call renderer with `buildChild` callback
5. Renderer may call `buildChild` recursively for nested nodes.
6. Final Flutter widget tree is returned to the screen.

---

## 5) Component Catalog: Inputs and Outputs

Below is current behavior of each built-in component.

### 5.1 scaffold

Input properties:
- `backgroundColor` (hex string)

Structure input:
- supports `child`

Output:
- Flutter `Scaffold`
- body is `SingleChildScrollView(child)` if child exists
- otherwise `SizedBox.shrink()`

### 5.2 column

Input properties:
- `mainAxisAlignment`
- `crossAxisAlignment`

Structure input:
- supports `children`

Output:
- Flutter `Column`
- `mainAxisSize` is hardcoded to `MainAxisSize.min`

### 5.3 row

Input properties:
- `mainAxisAlignment`
- `crossAxisAlignment`

Structure input:
- supports `children`

Output:
- Flutter `Row` wrapped by `IntrinsicHeight`
- `mainAxisSize` is hardcoded to `MainAxisSize.min`

### 5.4 container

Input properties:
- `padding`
- `margin`
- `color`
- `borderRadius`

Structure input:
- supports `child`

Output:
- Flutter `Container`
- if both borderRadius and color exist, uses `decoration`
- if borderRadius missing, uses direct `color`

### 5.5 text

Input properties:
- `value`
- `fontSize`
- `fontWeight`
- `color`
- `textAlign`

Output:
- Flutter `Text`
- defaults:
  - value: empty string
  - fontSize: 16.0
  - fontWeight: normal
  - textAlign: start

### 5.6 button

Input properties:
- `label`
- `backgroundColor`
- `borderRadius`
- `padding`
- `alignment`

Output:
- Flutter `ElevatedButton`
- default style fallback:
  - padding: horizontal 16, vertical 12
  - borderRadius: 8
- if alignment provided, wraps button in `Align`
- current action behavior: `onPressed: () {}` (no event binding yet)

### 5.7 card

Input properties:
- `elevation`
- `borderRadius`
- `color`

Structure input:
- supports `child`

Output:
- Flutter `Card`
- defaults:
  - elevation: 1.0
  - borderRadius: 4

### 5.8 spacer

Input properties:
- `flex`

Output:
- Flutter `Spacer(flex: ...)`
- default flex: 1

### 5.9 image

Input properties:
- `source` (`network` | `asset` | `file`)
- `url`
- `width`
- `height`
- `fit` (`fill`, `contain`, `cover`, `fitWidth`, `fitHeight`, `scaleDown`)

Output:
- network source -> `Image.network`
- asset source -> `Image.asset`
- file source -> placeholder container with "File images not yet supported"
- errorBuilder fallback -> gray box with broken image icon

---

## 6) Output Model

Engine outputs exist at multiple levels.

### 6.1 State Output

`VariantCubit` output states:
- `VariantInitial`
- `VariantLoading`
- `VariantSuccess(ScreenConfig config)`
- `VariantFailure(String message)`

### 6.2 UI Output

`VariantScreen` renders:
- loading indicator for initial/loading states
- rendered dynamic widget tree on success
- red error text block on failure

### 6.3 Logging Output

During parse validation:
- schema validation errors are logged via `print(...)`
- parsing continues (lenient mode)

### 6.4 Fallback Output Behavior

- unknown renderer type in `ScreenRenderer` map -> `SizedBox.shrink()`
- invalid optional property values -> null/defaults via parsers
- missing required schema property -> warning log (not hard stop)
- unknown enum component type string -> throws, leading to `VariantFailure`

---

## 7) Property Parser Contract Reference

`PropertyParsers` currently provides:

- `parseColor(String?) -> Color?`
- `parseMainAxisAlignment(String?) -> MainAxisAlignment`
- `parseCrossAxisAlignment(String?) -> CrossAxisAlignment`
- `parseEdgeInsets(dynamic) -> EdgeInsets?`
- `parseBorderRadius(dynamic) -> BorderRadius?`
- `parseFontWeight(String?) -> FontWeight`
- `parseTextAlign(String?) -> TextAlign`
- `parseAlignment(String?) -> AlignmentGeometry?`
- `parseDouble(dynamic) -> double?`
- `parseImageFitString(String?) -> String`
- `parseImageSource(String?) -> String`

Important behavior:
- Most parsers are permissive and return null/default on invalid values.
- This reduces crashes but can hide bad config data.

---

## 8) Validation System Contract

Validation is schema-based and centralized in:
- `ComponentSchema`
- `ComponentSchemas`

Validation checks:
1. Required properties exist.
2. Unknown properties are tolerated (not fatal).
3. `propertyTypes` are currently descriptive metadata, not hard runtime type enforcement.

Runtime mode today:
- lenient
- warnings logged
- parse continues

---

## 9) Data Structures Summary

### ScreenConfig

Fields:
- `pageId: String`
- `pageName: String`
- `root: ComponentConfig`

### ComponentConfig

Fields:
- `type: GenericComponentType`
- `properties: Map<String, dynamic>`
- `child: ComponentConfig?`
- `children: List<ComponentConfig>?`

---

## 10) Active vs Legacy/Inactive Paths

### Active path (used now)

- `VariantRepository` -> `AssetVariantRepository`
- `VariantCubit`
- `VariantScreen`
- `ScreenRenderer.withPrimitives()`
- component renderers under `lib/engine/tree/renderers/`

### Present but not active in runtime path

- `lib/engine/registry/component_registry.dart`
  - String-based registry exists but current runtime uses enum-based renderer map in `ScreenRenderer.withPrimitives()`.

- `lib/config/config_loader.dart`
  - Commented legacy loader.

- `lib/config/app_config.dart`, `assets/config/dashboard.json`, `assets/config/config.json`
  - Represent older or alternative config shapes.
  - Not the primary structure expected by `AssetVariantRepository._parseScreenConfig`.

Implication:
- For production runtime today, follow the `id/pageName/root` + recursive `type/child/children` contract.

---

## 11) Error Scenarios and Current Handling

1. Missing file (`assets/config/{id}.json` not found)
- repository throws
- cubit catches
- UI shows `VariantFailure` message

2. Unknown component type string
- parser throws `ArgumentError`
- cubit catches
- UI shows failure state

3. Missing required schema property
- schema throws `ComponentSchemaError`
- repository logs warning and continues (lenient)

4. Invalid property format (for example bad color hex)
- parser returns null/default
- widget renders with fallback/default look

---

## 12) Practical JSON Authoring Rules (Current Engine)

Use these rules to avoid runtime surprises:

1. Keep top-level keys exactly: `id`, optional `pageName`, `root`.
2. Ensure every component node has a valid enum `type`.
3. Place nested single content in `child`; list content in `children`.
4. Use parser-supported string values for alignments and text options.
5. Use valid hex for colors (`#RRGGBB`).
6. Prefer numbers for numeric fields (avoid numeric strings except where parser explicitly supports it).
7. Do not rely on button actions yet; onPressed is currently a no-op.

---

## 13) Minimal Valid Example

```json
{
  "id": "myPage",
  "pageName": "My Page",
  "root": {
    "type": "scaffold",
    "backgroundColor": "#FFFFFF",
    "child": {
      "type": "column",
      "crossAxisAlignment": "stretch",
      "children": [
        {
          "type": "container",
          "padding": 16,
          "child": {
            "type": "text",
            "value": "Hello Runtime UI",
            "fontSize": 20,
            "fontWeight": "bold",
            "color": "#222222"
          }
        },
        {
          "type": "button",
          "label": "Action",
          "backgroundColor": "#2196F3",
          "borderRadius": 10
        }
      ]
    }
  }
}
```

---

## 14) Reusable Context Block for Other Chats

Use this block to quickly brief another assistant:

```text
Project: SOOQ Merchant Flutter app.
Engine type: JSON-driven recursive UI renderer.

Active flow:
Home -> /variant/:id -> VariantScreen -> VariantCubit -> AssetVariantRepository -> ScreenConfig -> ScreenRenderer.withPrimitives() -> widgets.

Input contract:
- JSON file path: assets/config/{id}.json
- Top-level keys: id (required), pageName (optional), root (required)
- Node keys: type (required), child (optional), children (optional), plus properties
- Supported component types: scaffold, column, row, container, text, button, card, spacer, image

Important behavior:
- Schema validation is lenient (warns, does not fail parse)
- Unknown component type fails parse
- Unknown renderer returns SizedBox.shrink
- Button onPressed is currently no-op
- dataContext exists in API but is not used by built-in renderers yet

Output:
- Cubit states: initial/loading/success/failure
- Success output: rendered Flutter widget tree from JSON config
- Failure output: error message UI in VariantScreen
```

---

## 15) Source of Truth

If documentation and code diverge, code is the source of truth.

Primary source files:
- `lib/features/variantscreen/data/repos/variant_repository.dart`
- `lib/engine/screen_renderer/screen_renderer.dart`
- `lib/engine/tree/renderers/*.dart`
- `lib/engine/tree/parsers/property_parsers.dart`
- `lib/engine/validation/component_schemas.dart`
- `lib/features/variantscreen/presentation/views/variant_screen.dart`
