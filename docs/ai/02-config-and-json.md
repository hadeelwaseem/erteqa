# 02 — Config and JSON

## AI must know

- **Primary config:** `assets/config/mobile_production_v2.json` (~4700 lines, schemaVersion `1.0`).
- **Top-level keys:** `schemaVersion`, `app`, `theme`, `navigation`, `pages`.
- **Pages are not separate files** — one JSON file; `VariantRepository` selects by `pageRoute` or `id`.
- **Changing merchant UI** = edit JSON + hot restart; rarely need Dart unless new component type or binding.

## Top-level schema

```json
{
  "schemaVersion": "1.0",
  "app": {
    "name": "SOOQ Merchant Mobile",
    "bundleId": "com.sooq.merchant.mobile",
    "apiBaseUrl": "https://...",
    "tenantId": "uuid",
    "tenantSlug": "merchant-slug"
  },
  "theme": { "mode", "colors", "typography", "radius", "spacing", "buttons" },
  "navigation": {
    "type": "tabs",
    "initialRoute": "/splash",
    "shellExcludeRoutes": ["/splash", "/auth/login", "..."],
    "tabs": [{ "id", "label", "icon", "route" }]
  },
  "pages": [{ "id", "route", "title", "background", "scroll", "appBar?", "body": [] }]
}
```

Parsed by `MobileAppConfig.fromJson` in `lib/config/mobile_app_config.dart`.

## Page body nodes

Each node in `body[]`:

| Field | Required | Notes |
|-------|----------|-------|
| `id` | yes | Stable identifier |
| `type` | yes | Maps to `GenericComponentType` string |
| `props` | yes | Flat key/value; includes `semanticType` metadata |
| `style` | optional | padding, margin, colors → merged into properties |
| `tap` | optional | Action map — see [04-actions-and-requests.md](04-actions-and-requests.md) |
| `child` / `children` | optional | Tree structure |
| `itemBuilder` | optional | Repeat/list templates |

### Data blocks (in `props.data`)

```json
"data": {
  "source": "collection",
  "id": "all-products",
  "requestKey": "product-list",
  "requestUrl": "/api/v1/public/products?page=0&size=20",
  "page": 0,
  "size": 20
}
```

`EngineRequestMapper` reads `requestUrl` + `requestKey`. `VariantScreen` executes matching cubit loads.

### Dynamic field paths

- `valuePath`: `"item.name"` — text from list item
- `urlPath`: `"item.image"` — image URL from item
- Fallback `value` / `url` when path missing

## Navigation rules

- **Tab routes** — shown in `TabShellWidget` bottom nav.
- **shellExcludeRoutes** — full-screen routes without tab bar (auth, splash, checkout, `/product/details/:productId`).
- **Dynamic segments** — `:productId`, `:categorySlug` in route strings; params passed to `VariantScreen.routeParams`.

## Config Dart models

| File | Model |
|------|-------|
| `component_config.dart` | `ComponentConfig` |
| `screen_config.dart` | `ScreenConfig` |
| `mobile_app_config.dart` | `MobileAppConfig` |
| `navigation_config.dart` | `NavigationConfig`, tabs |
| `app_config.dart` | Legacy — prefer `MobileAppConfig` |

## Asset files

| File | Status |
|------|--------|
| `mobile_production_v2.json` | **Active** (main.dart) |
| `mobile_production.json` | Older variant |
| `mobile_component.json` | Component experiments |
| `mobile_component_flow_demo.json` | Demo flows |

## Switching config variant

Change in `lib/main.dart`:

```dart
const _kActiveConfig = 'mobile_production_v2';
```

Loads `assets/config/mobile_production_v2.json` via `AppConfigLoader`.

## Legacy: simple screen JSON

Still supported by `AssetVariantRepository` for standalone files:

```json
{ "id": "page-id", "pageName": "Name", "root": { "type": "scaffold", "child": { ... } } }
```

Production uses **builder format** inside `pages[]`, not separate per-page asset files.

## Anti-patterns

- Adding new screens only in Dart (`MaterialPageRoute` to custom widgets) for merchant flows
- Nesting objects inside `props` (except documented `data`, `tap`)
- Hardcoding API URLs in renderers instead of JSON `requestUrl`

## Related

- [04-actions-and-requests.md](04-actions-and-requests.md)
- [03-engine.md](03-engine.md)
