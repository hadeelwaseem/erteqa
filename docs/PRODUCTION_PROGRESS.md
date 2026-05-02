# Production Progress (Tree-Based UI Engine)

This file summarizes the current production progress, what was established from the builder JSON format, and what remains to be done.

---

## 1) Objective Recap

Production validates a runtime JSON-driven UI engine that can:
- Build a full screen layout at runtime
- Swap JSON to replace the screen without hardcoded layout switching
- Update UI without restarting the app

---

## 2) What Is Implemented

### Engine Core
- Tree-based component model: [lib/config/component_config.dart](lib/config/component_config.dart)
- Screen envelope model: [lib/config/screen_config.dart](lib/config/screen_config.dart)
- Recursive renderer: [lib/engine/screen_renderer/screen_renderer.dart](lib/engine/screen_renderer/screen_renderer.dart)
- Primitive renderers under [lib/engine/tree/renderers](lib/engine/tree/renderers)
- Property parsing helpers: [lib/engine/tree/parsers/property_parsers.dart](lib/engine/tree/parsers/property_parsers.dart)

### Supported Component Types (Current)
Supported types are defined in [lib/core/enums/generic_component_type.dart](lib/core/enums/generic_component_type.dart) and wired in ScreenRenderer:
- scaffold
- column
- row
- container
- text
- button
- card
- spacer
- image
- appBar
- divider
- icon
- richtext
- unsupported (fallback)

### Variant Loading
- JSON loading + parsing: [lib/features/variantscreen/data/repos/variant_repository.dart](lib/features/variantscreen/data/repos/variant_repository.dart)
- Variant screen uses ScreenRenderer.withPrimitives()

---

## 3) Builder JSON Support (mobile_component.full.json)

The VariantRepository now supports a builder-style JSON format (like docs/mobile_component.full.json) in addition to the simple page format.

### Builder Format Handling
- Root contains `pages`, `navigation`, `app`, `theme`
- The repository selects a page by `route` or `id`
- `appBar` (if present) becomes the first child in the rendered tree
- `body` array becomes the main children list

### Property Normalization Rules
The builder JSON is normalized into ComponentConfig properties:
- `props` is merged into properties
- `style.padding`, `style.margin`, `style.borderRadius`, `style.background`, `style.color`, `style.width`, `style.height`
- `tap` and `data` are preserved
- `crossAxis` -> `crossAxisAlignment`
- `mainAxis` -> `mainAxisAlignment`
- `align` -> `textAlign`
- `spacer.size` -> `height`

### Resulting Structure
A selected builder page is converted into:

- ScreenConfig
  - pageId
  - pageName
  - root = scaffold
    - child = column (crossAxisAlignment: stretch)
      - children = [appBar?, ...body]

---

## 4) Known Gaps / Current Limitations

- Builder JSON includes many types that are not supported yet (e.g. productList, productCard, categoryList, hero, statsRow, etc.)
- Unsupported types are mapped to `GenericComponentType.unsupported`
- No ActionDispatcher or DataResolver yet
- Theme tokens from builder JSON are not applied to renderers
- Layout gap and overflow behaviors are not fully supported

---

## 5) Next Steps (Future Work)

### A) Expand Component Coverage
Implement renderers and schema rules for types referenced by builder JSON:
- productList, productCard, categoryList, cartSummary, checkoutForm
- searchBar, hero, statsRow, logosRow
- imageGallery, videoPlayer, badge
- stack, scroll (if required by Rules.md)

### B) Action System
- Add ActionDispatcher
- Bind `tap` to actions (navigate, openUrl, addToCart, etc.)

### C) Data System
- Add DataResolver
- Wire `data` blocks to runtime data sources

### D) Layout Features
- `gap` for row/column
- row overflow handling (wrap/scroll/clip)
- optional explicit scroll handling per page

### E) Schema and Validation
- Enforce schemaVersion 1.0
- Validate props against ComponentSchemas in CI
- Expand ComponentSchemas for all supported types

### F) Documentation and Tests
- Update examples to match builder JSON
- Add renderer unit tests for each supported type

---

## 6) Current JSON Formats

### Simple Screen JSON (Supported)
```json
{
  "id": "classic",
  "pageName": "Classic",
  "root": {
    "type": "scaffold",
    "backgroundColor": "#FFFFFF",
    "child": {
      "type": "column",
      "children": []
    }
  }
}
```

### Builder JSON (Supported)
See [docs/mobile_component.full.json](docs/mobile_component.full.json) for structure.

---

## 7) Status Summary

- Tree-based rendering pipeline is in place and stable for supported types.
- Builder JSON support is established, but only a subset of node types render today.
- The biggest blockers are unsupported component types and missing action/data systems.
