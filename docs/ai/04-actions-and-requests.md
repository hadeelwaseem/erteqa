# 04 — Actions and Requests

## AI must know

- **`tap`** in JSON triggers `EngineActionDispatcher` (navigate, apiCall, cubitCall).
- **`props.data.requestUrl`** triggers `EngineRequestMapper` → cubit loads in `VariantScreen`.
- Do not add product-fetch logic to renderers — extend mapper + `VariantScreen` wiring instead.

## Actions (`tap`)

### JSON shape

```json
"tap": {
  "type": "navigate",
  "route": "/product/details/:productId"
}
```

### Supported types

| type | Behavior |
|------|----------|
| `navigate` | `context.go(resolvedRoute)` — `:param` from `routeParams`, `dataContext`, or `item` |
| `apiCall` | HTTP via `ApiService` (auth headers when needed) |
| `cubitCall` | Invokes registered cubit methods (e.g. auth logout) |

Optional: `requireValidForm`, `formId` — validates `FormStateStore` before dispatch.

File: `lib/engine/actions/action_dispatcher.dart`.

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
- Hardcoding navigation in feature views for JSON-driven routes
- Duplicate request parsing outside `EngineRequestMapper`

## Related

- [07-feature-product.md](07-feature-product.md)
- [08-feature-variant-shell.md](08-feature-variant-shell.md)
