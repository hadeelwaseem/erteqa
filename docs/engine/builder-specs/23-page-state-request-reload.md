# Builder spec: Page state and request reload

> **Phase:** Engine orchestration — tab-filtered lists + path-bound requests  
> **Status:** `implemented-in-json`  
> **Active config:** `mobile_production_v2`  
> **Created:** 2026-06-10  

---

## Summary

The mobile engine supports **page-scoped UI state** (`pageState`), **request reload**, **queryBindings** (query params), **pathBindings** (URL path placeholders), and **dynamic tabs** so lists/grids can bind to separate APIs without nested payloads.

Reference pages:

- `/orders` — **static** status tabs → `queryBindings.status`
- `/products` — **dynamic** category tabs + `queryBindings.categoryId` / `fallbackRequestUrl`
- `/categories` — master list + products grid → `pathBindings` + `primeFromRequest`

---

## Tab patterns (static vs dynamic)

| Pattern | Tab labels from | Use when | Example |
|---------|-----------------|----------|---------|
| **Static filter tabs** | JSON `data.items[]` | Filter dimension is fixed (enum); not derived from list rows | Order status: الكل / مؤكد / ملغي |
| **Dynamic tabs** | API via `itemsPath` + optional `data.staticItems` prefix | Options come from a separate request | Product categories on `/products` |

Static example (`/orders`): each tab item carries `status`; list uses `queryBindings.status`.

Dynamic example (`/products`):

```json
"props": {
  "itemsPath": "dataContext.requests.category-tree.data",
  "itemLabelPath": "name",
  "itemValuePath": "slug"
},
"data": {
  "requestKey": "category-tree",
  "requestUrl": "/api/v1/public/categories",
  "staticItems": [{ "title": "الكل", "index": 0, "slug": "" }]
}
```

---

## Gap vs production JSON

| Item | Exists in prod JSON? | Evidence |
|------|----------------------|----------|
| `setPageState` / `reloadRequest` | Yes | `/orders`, `/products`, `/categories` |
| `queryBindings` | Yes | `/orders` |
| `pathBindings` + `fallbackRequestUrl` | Yes | `/products` product-list, `/categories` grid |
| `primeFromRequest` | Yes | `/categories` category-products |
| Dynamic `tabs.itemsPath` | Yes | `/products` products-filter-tabs |

---

## Builder requirements

### 1. `pageState` (runtime)

Always present in `dataContext` as `pageState: {}` (may be empty). Cleared on page route/param change.

### 2. `setPageState` / `reloadRequest`

All keys in `values` are applied; missing/empty resolved values **remove** the pageState key.

Sources: `tap`, `item`, `form`, `pageState`, `value`.

### 3. `queryBindings`

Query param name → binding (e.g. `status`). Use for static filter tabs when the API accepts a query param.

### 4. `pathBindings` + `fallbackRequestUrl`

Path placeholder → binding. When unresolved, use `fallbackRequestUrl` (browse-all) instead of deferring:

```json
"requestUrl": "/api/v1/public/categories/:categorySlug/products?page=0&size=20",
"fallbackRequestUrl": "/api/v1/public/products?page=0&size=20",
"pathBindings": {
  ":categorySlug": { "source": "pageState", "field": "selectedCategorySlug" }
}
```

Without `fallbackRequestUrl`, unresolved path requests use `deferInitialDispatch` (see `/categories`).

### 5. `primeFromRequest`

Auto-select first row from a source request when pageState key is empty (default-first on master/detail pages). **Do not** use on `/products` — الكل should remain default.

### 6. Dynamic tabs props

| Prop | Role |
|------|------|
| `itemsPath` | dataContext path to API rows |
| `itemLabelPath` | Field for chip title (e.g. `name`) |
| `itemValuePath` | Field copied into tap payload (e.g. `slug`) |
| `data.staticItems` | Prefix chips before dynamic items (e.g. الكل) |

---

## Reference wiring

| Route | Pattern |
|-------|---------|
| `/orders` | Static tabs + `queryBindings.status` |
| `/products` | Dynamic category tabs + `queryBindings.categoryId` + browse `fallbackRequestUrl` |
| `/categories` | listView master + deferred `category-products` grid + `primeFromRequest` |

---

## Mobile implementation files

| File | Role |
|------|------|
| `lib/engine/page/page_state_store.dart` | Page UI state store |
| `lib/engine/actions/action_dispatcher.dart` | `setPageState`, `reloadRequest` |
| `lib/engine/requests/request_mapper.dart` | Bindings, `fallbackRequestUrl`, `buildRuntimeRequest` |
| `lib/engine/tree/renderers/tabs_renderer.dart` | Static + dynamic tabs |
| `lib/features/variantscreen/presentation/views/variant_screen.dart` | Context, reload handler, prime hook |
