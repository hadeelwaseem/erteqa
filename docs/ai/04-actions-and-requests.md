# 04 — Actions and Requests

## AI must know

- **`tap`** in JSON triggers `EngineActionDispatcher` (navigate, apiCall, cubitCall, openUrl, openContact, openDrawer, closeDrawer).
- **`props.data.requestUrl`** triggers `EngineRequestMapper` → cubit loads in `VariantScreen`.
- Do not add product-fetch logic to renderers — extend mapper + `VariantScreen` wiring instead.

## Actions (`tap`)

### JSON shape

```json
"tap": {
  "type": "navigate",
  "route": "/product/details/:productId",
  "navigation_type": "push"
}
```

Omit `navigation_type` for default **clear stack** (`context.go`).

### Supported types

| type | Behavior |
|------|----------|
| `navigate` | [`AppNavigation`](../../lib/core/navigation/app_navigation.dart) — `push` or `go` per `navigation_type`; `:param` from `routeParams`, `dataContext`, or `item` |
| `apiCall` | HTTP via `ApiService` (auth headers when needed) |
| `cubitCall` | Auth cubit: `requestOtp`, `verifyOtp`, `logout` — runs `onSuccess` / `onFailure` action maps when applicable |
| `openUrl` | Opens `url` or `urlPath` in external app (`url_launcher`) |
| `openContact` | Builds URI from `channel` + `target` (string or `{source,field}`) — `whatsapp`, `tel`, `sms`, `email`, `url` |
| `openDrawer` / `closeDrawer` | Page chrome drawer |
| `setPageState` | Merge UI state into `pageState` (tab filters, selection); optional `onSuccess` chain |
| `reloadRequest` | Re-dispatch cubit load for a `requestKey` using current `pageState` + `queryBindings` |

Optional on navigate: `requireValidForm`, `formId` — validates `FormStateStore` before dispatch.

Optional on `openUrl` / `openContact` / others: `requireAuth: true` — if no session token, runs `onUnauthenticated` tap or navigates to `/auth/login`.

Builder handoff: [`docs/engine/builder-specs/18-contact-button-open-contact.md`](../engine/builder-specs/18-contact-button-open-contact.md).

File: `lib/engine/actions/action_dispatcher.dart`.

### `navigation_type` (navigate only)

| Value | Aliases | API |
|-------|---------|-----|
| _(omit)_ / unknown | — | `context.go` (default) |
| `clear_stack` | `clearstack`, `reset`, `go` | `context.go` |
| `push` | `stack` | `context.push` |

Use **`push`** for drill-down (e.g. product detail) so AppBar back (`context.pop`) returns. Use **`clear_stack`** or omit for auth success, splash, logout landing.

Builder handoff: [`docs/engine/builder-specs/13-navigation-type.md`](../engine/builder-specs/13-navigation-type.md).

### Auth navigation notes

- Post-login home: JSON `verifyOtp` → `onSuccess.navigate` to `/home` only — `_AuthRequestHost` shows success toast, **does not** call `context.go`.
- Logout: `cubitCall` `logout` clears token; `onSuccess.navigate` to `/auth/login` with `navigation_type: clear_stack` (see settings in prod JSON).

### Route resolution

- `dataContext['routeParams']` from GoRouter
- `dataContext['item']` for list taps — maps `productId` → `slug` when needed
- Used by product cards navigating to detail routes

## Requests (`data` blocks)

### Collection example

```json
"props": {
  "semanticType": "ProductList",
  "data": {
    "source": "collection",
    "requestKey": "product-list",
    "requestUrl": "/api/v1/public/products?page=0&size=20",
    "page": 0,
    "size": 20
  }
}
```

### Mapper output

`EngineRequestMapper.collectRequests(screenConfig, routeParams:, queryParams:)` → `List<EngineMappedRequest>` with:

- `key` (requestKey)
- `requestUrl` (resolved `:slug` placeholders)
- `semanticType`, pagination fields (`page`, `size`, `sort`, `q`, …)

File: `lib/engine/requests/request_mapper.dart`.

### Cubit routing (VariantScreen)

| URL pattern | Cubit |
|-------------|-------|
| `/api/v1/public/products` (browse) | `ProductCubit` |
| `/api/v1/public/categories/{slug}/products` | `ProductCubit` |
| `/api/v1/public/products/search` | `ProductSearchCubit` |
| `/api/v1/public/products/autocomplete` | `ProductAutocompleteCubit` |
| `/api/v1/public/products/{slug}` | `ProductDetailCubit` |
| `/api/v1/public/categories` (tree/list) | `CategoryCubit` |

Results stored in `dataContext` under `requests.{requestKey}` for renderers/itemBuilder.

### Tab-filtered lists (`pageState` + `reloadRequest`)

Two tab patterns:

**Static filter tabs** — fixed enum in JSON (not from list response). Example: `/orders` status.

1. `tabs.data.items[]` with metadata (e.g. `status`)
2. Tab `tap`: `setPageState` → `onSuccess.reloadRequest`
3. List `queryBindings` maps pageState to query params

**Dynamic tabs** — labels from API. Example: `/products` categories.

1. `tabs.data` loads source request (e.g. `category-tree`) + optional `staticItems` prefix (الكل)
2. `itemsPath` / `itemLabelPath` / `itemValuePath` build chips from `dataContext.requests.*.data`
3. Tab `tap`: `setPageState(selectedCategorySlug)` → `reloadRequest`
4. Grid uses `pathBindings` + `fallbackRequestUrl` when browse vs category URL differs

Builder handoff: [`docs/engine/builder-specs/23-page-state-request-reload.md`](../engine/builder-specs/23-page-state-request-reload.md). References: `/orders`, `/products`, `/categories`.

### Path-bound requests (`pathBindings` + `primeFromRequest`)

For a master list + detail grid on one page (e.g. categories + category products):

1. Master list loads via first `requestKey` (e.g. `category-tree`).
2. Detail grid uses `requestUrl` with `:categorySlug` and `pathBindings` from `pageState.selectedCategorySlug`.
3. `primeFromRequest` auto-selects the first master row on load and reloads the detail grid.
4. Master row `tap`: `setPageState` from `item.slug` → `reloadRequest` for detail `requestKey`.

### itemBuilder repeat

```json
"itemBuilder": {
  "type": "repeat",
  "source": "dataContext.requests.product-list.data",
  "item": { "type": "card", "props": { "valuePath": "item.name" } }
}
```

## Form state

- `FormStateStore` in `dataContext` under `FormStateStore.contextKey`
- `form` / `textFormField` renderers register fields by id
- Actions with `requireValidForm: true` block until valid

## Anti-patterns

- Calling `ProductRepo` from `TextRenderer`
- Hardcoding navigation in feature views for JSON-driven routes (e.g. duplicate `context.go` on `AuthAuthenticated` when JSON already has `onSuccess.navigate`)
- Navigate-only logout without `cubitCall` `logout` (token remains; redirect sends user back to home)
- Duplicate request parsing outside `EngineRequestMapper`

## Related

- [07-feature-product.md](07-feature-product.md)
- [08-feature-variant-shell.md](08-feature-variant-shell.md)
