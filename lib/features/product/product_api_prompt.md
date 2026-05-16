# Product Module — API Implementation Prompts

This file defines **three sequential prompts**. Run each in a **separate chat**. Do not start the next prompt until the previous one meets its **Definition of Done**.

Copy **one prompt section only** (from its heading through its Definition of Done) into a new chat, plus the shared **Appendix A** block if the agent needs rules context.

---

## Roadmap

| Prompt | Endpoints | Why separate |
|--------|-----------|--------------|
| **1 — Lists & foundation** | Browse products, category products | Shared pagination envelope, `ProductCubit`, engine list wiring; establishes repo patterns |
| **2 — Search & autocomplete** | Search, autocomplete | Different response shapes, `CancelToken`, debounce — easy to break list code if done together |
| **3 — Detail & categories** | Product detail, category tree, single category | Largest models (variants, images, blocks); no dependency on search |

```text
Prompt 1  →  merge / verify  →  Prompt 2  →  merge / verify  →  Prompt 3
```

**Authority (all prompts):**
1. [`docs/ENDPOINTS_AND_FEATURES_GUIDE.md`](../../../docs/ENDPOINTS_AND_FEATURES_GUIDE.md)
2. [`lib/features/product/CustomerProductFlutterGuide.md`](CustomerProductFlutterGuide.md) — see endpoint sections cited in each prompt
3. Auth reference: `lib/features/auth/data/repos/auth_repo_impl.dart`, `test/features/auth/`

---

# Prompt 1 — Lists & Repository Foundation

> **Prerequisite:** None. `getProducts` exists partially — harden and extend it, do not rewrite from scratch unless necessary.

## Goal

Deliver production-ready **paginated product lists** (browse + category products) and the **shared repository foundation** every later prompt builds on.

## In scope (2 endpoints)

| Method | Path | Repo method |
|--------|------|-------------|
| GET | `/api/v1/public/products` | `getProducts` |
| GET | `/api/v1/public/categories/{slug}/products` | `getCategoryProducts` |

Guide sections: **Endpoint 1** (Browse), **Endpoint 7** (Category products) in `CustomerProductFlutterGuide.md`.

## Out of scope for this prompt

- Search, autocomplete, product detail, category tree, single category
- New JSON screens or hardcoded Dart pages
- `freezed` / code generation

## Implementation tasks

### 1. Repository contract

Create or update `lib/features/product/data/repos/product_repo.dart`:

```dart
abstract class ProductRepo {
  Future<Either<Failure, ProductListResponse>> getProducts({
    required int page,
    required int size,
    String? sort,
    String? tenantId,
  });

  Future<Either<Failure, ProductListResponse>> getCategoryProducts({
    required String categorySlug,
    required int page,
    required int size,
    String? sort,
    String? tenantId,
  });
}
```

### 2. Repository implementation

Refactor `product_repo_impl.dart`:

- Inject `Dio` only (base URL from `NetworkConfig` via Dio — no hardcoded hosts).
- Add private helpers: `_requireEnvelope`, `_mapDioException`, `_executeWithRetry` (mirror `AuthRepoImpl`).
- Path constants: `_productsPath`, `_categoryProductsPath(slug)`.
- Validate `success`, parse `data` as `List`, `meta` at envelope root.
- Query params: `page`, `size`, optional `sort`.
- Header: `X-Tenant-ID` when `tenantId` is non-empty.
- Retry idempotent GET on 429/5xx (max 3, injectable `sleep` for tests).
- `AppLogger.debug` with `[ProductRepo]` prefix.

### 3. Models (extend existing)

- `product.dart`, `product_meta.dart`, `product_list_response.dart` — keep `Equatable`; ensure UI getters `name`, `image`, `price`, `currency`.
- Resolve image URLs via `NetworkConfig.assetBaseUrl` from service locator (replace `kBaseUrlAsset` in new code paths).

### 4. ProductCubit

Update `product_cubit.dart`:

- Add `getCategoryProducts({categorySlug, page, size, sort, requestKey, isLoadMore})`.
- On `loadNextPage` with `isLoadMore: true`, **append** new items to prior list in emitted success state (engine/scaffold expect growing list).
- Keep `if (isClosed) return` before every `emit`.
- States: `requestKey`, `isLoadMore` (already exist — use consistently).

### 5. Service locator

In `service_locator.dart`:

- Register `ProductRepo` → `ProductRepoImpl` (interface type, not only impl).
- Keep `ProductCubit` as `registerFactory`.

### 6. Engine — list requests only

Update `lib/engine/requests/request_mapper.dart`:

- Dispatch when URL contains `/public/products` **and does not** contain `/search` or `/autocomplete`.
- Dispatch when URL matches `/public/categories/` + `/products`.
- Call `getProducts` or `getCategoryProducts` with parsed `page`/`size` from JSON `data` or query string.
- Pass `tenantId` from storage/config as today.

Do **not** add search/detail/category-tree dispatch yet.

### 7. Tests

Create `test/features/product/`:

- `support/product_test_utils.dart` — `FakeHttpClientAdapter`, sample browse + category-products JSON fixtures.
- `data/repos/product_repo_impl_test.dart` — happy path, `success: false`, bad `data` type, 429 retry, tenant header present.
- `data/models/product_test.dart` — `fromJson`, missing images, getter `name`/`price`.
- `presentation/manager/product_cubit_test.dart` — loading → success, `loadNextPage` when `!hasNext` skips call.

Run: `flutter test test/features/product`

## Definition of Done (Prompt 1)

- [ ] `ProductRepo` interface with `getProducts` + `getCategoryProducts`
- [ ] Envelope validation + retry on both methods
- [ ] `ProductCubit.getCategoryProducts` + load-more append works
- [ ] `EngineRequestMapper` routes browse + category product URLs only
- [ ] `flutter test test/features/product` passes
- [ ] `flutter analyze lib/features/product` clean
- [ ] Existing JSON screens with `requestUrl` `/api/v1/public/products?...` still load (manual smoke OK)

**Handoff to Prompt 2:** `ProductRepo` + `_requireEnvelope` + test utils exist; list parsing is stable. Search will add methods to the same interface.

---

# Prompt 2 — Search & Autocomplete

> **Prerequisite:** Prompt 1 complete and merged. `ProductRepo`, `Product`, `ProductMeta`, envelope helpers, and `test/features/product/support/` must exist.

## Goal

Implement **search** and **autocomplete** with correct non-list response shapes, request cancellation, and cubits separate from list pagination.

## In scope (2 endpoints)

| Method | Path | Repo method |
|--------|------|-------------|
| GET | `/api/v1/public/products/search` | `searchProducts` |
| GET | `/api/v1/public/products/autocomplete` | `autocomplete` |

Guide sections: **Endpoint 2** (Search), **Endpoint 3** (Autocomplete).

## Out of scope

- Changing browse/category list behavior from Prompt 1 (unless fixing a bug)
- Product detail, categories tree
- Caching search results (guide says do not cache)

## Implementation tasks

### 1. Models

Add:

- `lib/features/product/data/models/product_search_result.dart`
  - Fields: `query`, `products` (`List<Product>`), `meta` (`ProductMeta`), `suggestions`, `popularProducts`, `totalResults`
  - Parse from `data` **object**, not envelope list
- `lib/features/product/data/models/product_autocomplete_result.dart`
  - Fields: `products` (lightweight items: `productId`, `titleAr`, `titleEn`, `slug`, `basePrice`, `thumbnailUrl`), `suggestions`
  - Or separate `AutocompleteProductItem` if cleaner

### 2. Repository

Extend `product_repo.dart`:

```dart
Future<Either<Failure, ProductSearchResult>> searchProducts({
  String? q,
  String? categoryId,
  String? tagId,
  double? minPrice,
  double? maxPrice,
  bool? inStockOnly,
  required int page,
  required int size,
  String? sort,
  String? tenantId,
  CancelToken? cancelToken,
});

Future<Either<Failure, ProductAutocompleteResult>> autocomplete({
  required String q,
  String? tenantId,
  CancelToken? cancelToken,
});
```

Implement in `product_repo_impl.dart`:

- Search: build query map; parse nested `data.products` + `data.meta`.
- Autocomplete: reject calls with `q.length < 3` in repo or cubit (return `Right` empty result without HTTP — pick one layer and document it).
- Pass `cancelToken` to `_dio.get`.
- On `DioExceptionType.cancel`, return without treating as user error (or map to a dedicated silent cancel type consumed by cubit).
- Retry search GET like Prompt 1; autocomplete may skip retry (low cost, high frequency).

### 3. Cubits

**`product_search_cubit/`**

- States: initial, loading, success (`ProductSearchResult`, `requestKey`, `isLoadMore`), failure.
- Method `search(...)` with filter params.
- Method `loadNextPage` using `meta.hasNext`.
- Optional: 300ms debounce inside cubit OR document that UI debounces before calling.
- Store latest `CancelToken`; cancel before new search.

**`product_autocomplete_cubit/`**

- States: initial, loading, success, failure (failure only for real errors, not cancel).
- Method `fetchSuggestions(String q)` — no-op if `q.length < 3`.
- Cancel in-flight on new input.

### 4. Service locator

```dart
getIt.registerFactory<ProductSearchCubit>(() => ProductSearchCubit(getIt<ProductRepo>()));
getIt.registerFactory<ProductAutocompleteCubit>(() => ProductAutocompleteCubit(getIt<ProductRepo>()));
```

Wire cubits in screen host if search UI exists in config (e.g. `variant_screen` `MultiBlocProvider`).

### 5. Engine

Extend `request_mapper.dart`:

- URL contains `/public/products/search` → `ProductSearchCubit` (parse `q` from URL query if present).
- URL contains `/public/products/autocomplete` → `ProductAutocompleteCubit`.

Do not route these to `ProductCubit.getProducts`.

### 6. Tests

- `product_search_result_test.dart` — empty products + non-empty `suggestions`/`popularProducts`.
- `product_repo_impl_test.dart` — search happy path, `success: false`, cancel does not emit failure in cubit test.
- `product_search_cubit_test.dart` — debounce/cancel behavior (fake async).
- `product_autocomplete_cubit_test.dart` — skips API when `q.length < 2`.

Run: `flutter test test/features/product`

## Definition of Done (Prompt 2)

- [ ] `searchProducts` + `autocomplete` on `ProductRepo` with correct parsing
- [ ] `ProductSearchCubit` + `ProductAutocompleteCubit` registered and wired
- [ ] `CancelToken` prevents stale search/autocomplete results
- [ ] Engine routes search/autocomplete URLs to correct cubits
- [ ] All product tests pass
- [ ] Prompt 1 list tests still pass (no regressions)

**Handoff to Prompt 3:** All product **list-like** and **search** flows done. Detail and category metadata remain.

---

# Prompt 3 — Product Detail & Categories

> **Prerequisite:** Prompts 1 and 2 complete and merged. `ProductRepo` with list + search methods and shared test utils exist.

## Goal

Implement **product detail by slug** (conditional blocks) and **category navigation** (tree + single category).

## In scope (3 endpoints)

| Method | Path | Repo method |
|--------|------|-------------|
| GET | `/api/v1/public/products/{slug}` | `getProductDetail` |
| GET | `/api/v1/public/categories` | `getCategories` |
| GET | `/api/v1/public/categories/{slug}` | `getCategory` |

Guide sections: **Endpoint 4**, **Endpoint 5**, **Endpoint 6**.

## Out of scope

- Re-implementing browse/search/category-products (Prompts 1–2)
- Variant selector UI, image gallery widgets (JSON engine only unless config demands engine binding paths)

## Implementation tasks

### 1. Models

Add `category.dart` — recursive `children`, fields per guide.

Add `product_detail.dart` with nested types (single file or `product_detail/` folder if large):

- Top-level: `productId`, titles, descriptions, `slug`, SEO fields, `isAvailable`
- Optional blocks: `pricing`, `inventory`, `images`, `variants`, `categories`, `tags`, `attributes`
- Sub-models: `PricingBlock`, `InventoryBlock`, `ProductImage`, `Variant`, `OptionValue`, etc.
- All blocks nullable — parse only if key present (`include` param controls backend)

### 2. Repository

Extend `product_repo.dart`:

```dart
Future<Either<Failure, ProductDetail>> getProductDetail({
  required String slug,
  String? include, // comma-separated, default per guide
  String? tenantId,
});

Future<Either<Failure, List<Category>>> getCategories({String? tenantId});

Future<Either<Failure, Category>> getCategory({
  required String slug,
  String? tenantId,
});
```

Implement:

- Detail: path `/api/v1/public/products/$slug`, query `include`.
- Categories: path `/api/v1/public/categories`, `data` is array.
- Single category: path `/api/v1/public/categories/$slug`.
- **404** → `ServerFailure` with clear not-found message (or `ProductFailure` if added).
- Optional in-memory cache for `getCategories` (TTL ~1 day per guide).

### 3. Cubits

**`product_detail_cubit/`**

- `loadDetail(slug, {include})` → loading / success / failure
- Expose `ProductDetail` to engine via state (for future `dataContext` binding)

**`category_cubit/`**

- `loadTree()` → list of root categories
- `loadCategory(slug)` → single `Category` with children

### 4. Service locator

Register both cubits as factories.

### 5. Engine

Extend `request_mapper.dart`:

| URL pattern | Cubit |
|-------------|-------|
| `/public/categories` (exact or no extra segments) | `CategoryCubit.loadTree` |
| `/public/categories/{slug}` without `/products` | `CategoryCubit.loadCategory` |
| `/public/products/{slug}` (not search/autocomplete) | `ProductDetailCubit.loadDetail` |

Extract slug from path segment. Pass `include` from query string if JSON `requestUrl` contains it.

### 6. Tests

- `category_test.dart` — nested `children` parsing
- `product_detail_test.dart` — full payload + partial `include` (missing `variants` key)
- Repo tests: detail 404, categories happy path
- Cubit tests: load detail success/failure

Run: `flutter test test/features/product`

## Definition of Done (Prompt 3)

- [ ] All 7 product-module endpoints implemented across Prompts 1–3
- [ ] `getProductDetail`, `getCategories`, `getCategory` with nullable conditional blocks
- [ ] `ProductDetailCubit` + `CategoryCubit` registered
- [ ] Engine routes detail + category URLs correctly
- [ ] Full `flutter test test/features/product` passes
- [ ] Module checklist in Appendix B satisfied

**Module complete** when Prompts 1–3 Definitions of Done are all checked.

---

# Appendix A — Shared Rules (all prompts)

## Project constraints

- JSON-driven app — no hardcoded screens/flows in Dart.
- No HTTP in `presentation/views/`.
- No business logic in engine renderers.
- `Equatable` + hand-written `fromJson` — no `freezed` unless approved.
- `Either<Failure, T>` on all repo methods.

## Envelope (required in every repo method)

1. Body is `Map<String, dynamic>`.
2. If `success == false` → `Left(ServerFailure(...))` using `message`.
3. Validate `data` type before model parsing.
4. Paginated: `meta` at root next to `data`.

## Tenant & network

- Dio `baseUrl` from `NetworkConfig` (from `assets/config` → `MobileAppConfig`).
- `X-Tenant-ID` when tenant id known.
- No `Authorization` on `/api/v1/public/*`.

## Cubit rules

- Sealed states with `requestKey`, `isLoadMore` where applicable.
- `if (isClosed) return` after awaits.
- Use server `displayPrice` as-is.

## JSON engine pattern

```json
"data": {
  "requestKey": "product-list",
  "requestUrl": "/api/v1/public/products?page=0&size=20",
  "page": 0,
  "size": 20
}
```

```json
"itemBuilder": {
  "source": "dataContext.requests.product-list.data",
  "item": { "props": { "valuePath": "item.name" } }
}
```

## Anti-patterns

- Assuming search `data` is a `List`.
- Duplicate URL strings outside `product_repo_impl.dart`.
- Raw `Map` passed to UI/engine.
- `freezed` without project decision.
- Snackbars or `ScaffoldMessenger` in repos.

---

# Appendix B — Full module checklist (after Prompt 3)

- [ ] 7/7 endpoints on `ProductRepo`
- [ ] Envelope validation on every method
- [ ] `ProductCubit`, `ProductSearchCubit`, `ProductAutocompleteCubit`, `ProductDetailCubit`, `CategoryCubit`
- [ ] `EngineRequestMapper` covers all URL patterns
- [ ] `flutter test test/features/product` green
- [ ] No `Dio` in views
- [ ] Stable UI getters on list models (`name`, `image`, `price`)

---

# How to run in Cursor

1. New chat → paste **Prompt 1** + **Appendix A** → implement → verify Definition of Done.
2. New chat → paste **Prompt 2** + **Appendix A** → mention “Prompt 1 is merged” → implement.
3. New chat → paste **Prompt 3** + **Appendix A** → mention “Prompts 1–2 merged” → implement.

Optional first line for chats 2 and 3:

```text
Product API Prompt 2 (or 3). Prompt 1 (and 2) are complete per product_api_prompt.md Definition of Done.
Follow only the Prompt N section in lib/features/product/product_api_prompt.md.
```
