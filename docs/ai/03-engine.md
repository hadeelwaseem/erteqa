# 03 — Engine

## AI must know

- **24 component types** — all mapped in `ScreenRenderer._createDefaultRenderers` (including `unsupported` fallback).
- **Entry:** `ScreenRenderer.withPrimitives().render(screenConfig, context:, dataContext:)`.
- **No domain logic** in renderers — only layout, styling, path resolution from `dataContext`.
- New component type = enum + renderer + schema + register in `screen_renderer.dart`.

## Component types (current)

| Type | Renderer file | Role |
|------|---------------|------|
| `scaffold` | `scaffold_renderer.dart` | Page shell |
| `singleChildScrollView` | `single_child_scroll_view_renderer.dart` | Scroll wrapper |
| `column` | `column_renderer.dart` | Vertical layout |
| `row` | `row_renderer.dart` | Horizontal layout |
| `container` | `container_renderer.dart` | Box + padding |
| `listView` | `list_view_renderer.dart` | Scrollable list |
| `gridView` | `grid_view_renderer.dart` | Grid + itemBuilder |
| `text` | `text_renderer.dart` | Text + valuePath |
| `textFormField` | `text_form_field_renderer.dart` | Form fields |
| `form` | `form_renderer.dart` | Form grouping |
| `button` | `button_renderer.dart` | Buttons |
| `card` | `card_renderer.dart` | Material card |
| `spacer` | `spacer_renderer.dart` | Fixed gap |
| `image` | `image_renderer.dart` | Network/asset images |
| `appBar` | `app_bar_renderer.dart` | Top bar |
| `divider` | `divider_renderer.dart` | Divider line |
| `icon` | `icon_renderer.dart` | Material icons |
| `richtext` | `rich_text_renderer.dart` | Rich text |
| `videoPlayer` | `video_player_renderer.dart` | Video embed |
| `stack` | `stack_renderer.dart` | Layered overlays |
| `imageSlider` | `image_slider_renderer.dart` | Full-screen carousel |
| `timer` | `timer_renderer.dart` | Delayed navigate |
| `progressIndicator` | `progress_indicator_renderer.dart` | Loading spinner |
| `unsupported` | `unsupported_component_renderer.dart` | Unknown types |

Enum: `lib/core/enums/generic_component_type.dart`.

## semanticType vs type

- **`type`** — selects renderer (required).
- **`semanticType`** — documentation/metadata (e.g. `ProductList`, `Hero`); **does not** register a custom renderer. Complex commerce UIs are built from primitives (`gridView` + `itemBuilder` + `card`).

## Parsing pipeline

1. `AssetVariantRepository.load(variantId, pageRoute:)` reads `assets/config/{variantId}.json`.
2. Selects page from `pages[]` by `route` or `id`.
3. Normalizes builder nodes → `ComponentConfig` (merges `props` + `style`, maps axis names).
4. Validates structure (strict) + `ComponentSchemas` (lenient warnings).
5. Runs `LayoutConstraintValidator` on the synthetic scaffold (errors throw in debug; warnings logged).
6. Returns `ScreenConfig(pageId, pageName, root)`.

File: `lib/features/variantscreen/data/repos/variant_repository.dart`.

## ScreenRenderer behavior

- Recursive `_buildComponent` with debug path `_enginePath`.
- Injects `FormStateStore` and `EngineActionDispatcher` into `dataContext`.
- Resolves `tap` on non-button nodes via `GestureDetector`.
- `dataContextOverride` on nodes merges into child context.

## Property parsers

`lib/engine/tree/parsers/property_parsers.dart` — colors, padding, alignment, font sizes from dynamic JSON.

`lib/engine/tree/parsers/data_context_path.dart` — resolves dotted paths for repeat items.

## Validation

- `component_schema.dart` — per-type required/optional props
- `component_schemas.dart` — catalog aligned with `mobile_production_v2` (e.g. `valuePath`, `urlPath`, `gap`, `shadow`, `border`, `aspectRatio`, `variant`, `id`). Warns on unknown keys; does not block render. Button `onTap` is **runtime-injected** by `ScreenRenderer` from JSON `tap` — do not author `onTap` in JSON.
- `layout_constraint_validator.dart` — parse-time layout rules on every `AssetVariantRepository.loadVariant`; CI via `test/engine/validation/prod_layout_validator_test.dart` (0 errors on prod pages).

## Registry note

`ComponentRegistry` may exist historically; **production path uses enum map in `ScreenRenderer`**, not string registry.

## Adding a new component type

1. Add to `GenericComponentType` enum.
2. Create `lib/engine/tree/renderers/{name}_renderer.dart` implementing `ComponentRenderer`.
3. Register in `ScreenRenderer._createDefaultRenderers`.
4. Add schema in `component_schemas.dart`.
5. Document JSON shape in [09-workflows.md](09-workflows.md).
6. Add unit/widget test under `test/engine/`.

## Layout & constraints

- **Audit:** [LAYOUT_CONSTRAINT_AUDIT.md](../engine/LAYOUT_CONSTRAINT_AUDIT.md) — constraint flow, PASS/FAIL matrix, canonical JSON patterns.
- **Improvement plan:** [LAYOUT_IMPROVEMENT_PLAN.md](../engine/LAYOUT_IMPROVEMENT_PLAN.md) — how we reduce layout risk (presets, parse gates, safe renderers).
- **Parse-time validation:** `LayoutConstraintValidator` in `VariantRepository` (debug throws on errors) + secondary debug assert in `ScreenRenderer`.
- **Canonical patterns:**
  - **Splash / full-screen center:** `pages[].layout: "centered"` (engine forces `scroll: none`, root column max + stretch, injects `expand` if missing). See [15-page-layout-preset.md](../engine/builder-specs/15-page-layout-preset.md).
  - **Catalog:** `scroll: "vertical"` + `gridView`/`listView` with `enableInnerScroll: false` (outer page scroll only).
  - **Search toolbar:** `row` + `container` with `expand: true`, `expandAxis: "horizontal"`.
  - **Auth forms:** `scroll: "none"` on short static pages (validator whitelist).
- **Avoid:** `spacer` (legacy — use `gap` on column/row); nested `singleChildScrollView` (unwrapped at runtime); viewport centering under `scroll: vertical` without `expand` or `layout: centered`.

## Related

- [04-actions-and-requests.md](04-actions-and-requests.md)
- [08-feature-variant-shell.md](08-feature-variant-shell.md)
