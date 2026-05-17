# Endpoints and Features Guide

Last updated: 2026-05-17

This guide defines how to add new backend endpoints and how to organize feature files in this project.
Use it as the reference before creating a new API flow, a new feature module, or a new JSON-driven screen section.

## 1. Purpose

The project uses a feature-first Flutter structure with Cubit state management and a JSON-driven rendering engine.

When adding a new endpoint or feature, the goal is to keep the work separated into clear layers:
- UI and screens stay in `presentation/`
- API access and parsing stay in `data/`
- Shared infrastructure stays in `core/`
- Dynamic JSON screens stay in `assets/config/` and `lib/engine/`

Do not place API calls directly in widgets unless the codebase already follows that pattern for a specific legacy case.

## 2. Standard Feature Structure

Each feature should follow the same folder pattern:

```text
lib/features/<feature_name>/
├── data/
│   ├── models/
│   └── repos/
└── presentation/
    ├── manager/
    │   └── <feature>_cubit/
    └── views/
```

### What each folder contains

- `data/models/`
  - Response DTOs and entity models.
  - JSON parsing, `fromJson`, `toJson`, and compatibility getters.
  - Keep backend field translation here.

- `data/repos/`
  - Repository interface and repository implementation.
  - Endpoint URLs, query parameters, headers, and error mapping.
  - Do not put UI logic here.

- `presentation/manager/`
  - Cubits and state files.
  - Loading, success, failure, and pagination state.
  - Dispatch repository calls and expose simple screen state.

- `presentation/views/`
  - Flutter widgets, page composition, and UI-specific interaction handling.
  - Listen to cubits and transform state into visible UI.

## 3. New Endpoint Workflow

Use this order when adding a new API call:

1. Define or update the response model in `data/models/`.
2. Add the repository contract in `data/repos/<feature>_repo.dart`.
3. Implement the request in `data/repos/<feature>_repo_impl.dart`.
4. Add cubit methods and states in `presentation/manager/`.
5. Wire the cubit into the screen or page host.
6. Register dependencies in `lib/core/utils/service_locator.dart`.
7. If the endpoint is driven by JSON config, update `assets/config/*.json` and the engine request mapping if needed.
8. Validate parsing, loading, and failure behavior.

## 4. Repository Responsibilities

Repository implementations should own all transport details:

- HTTP method selection
- Query parameter construction
- Path construction
- Headers and tenant/auth configuration
- Response envelope validation
- Parsing raw response data into models
- Converting transport errors into `Failure`

### Repository file layout

- `<feature>_repo.dart`
  - Abstract contract.
  - Exposes methods the cubit can call.

- `<feature>_repo_impl.dart`
  - Concrete Dio/API implementation.
  - Builds `Uri`, applies headers, and parses response JSON.

### Repository rules

- Keep the endpoint URL in one place.
- Validate response type before parsing.
- Prefer typed parsing over passing raw JSON upward.
- Support pagination explicitly when the backend returns it.

### Repository return type

- Public repository methods return `Future<Either<Failure, T>>` from `dartz`.
- Cubits call repos and `fold` into loading / success / failure states.
- Do not throw from repositories for expected API errors; return `Left(Failure)`.

### API response envelope

Backend responses use a common wrapper. Repositories must validate it before parsing models:

```json
{
  "success": true,
  "message": null,
  "data": {},
  "meta": {},
  "timestamp": 1715824800000
}
```

Rules:

- Reject or map failures when `success == false` (use `message` / `detail` for user text).
- Confirm `data` matches the expected shape (list vs object) before `fromJson`.
- For paginated lists, read `meta` at the envelope root (sibling of `data`), not inside each item.
- Some endpoints use a non-array `data` object (for example search). Do not assume all list endpoints return `data: []`.

Reference: `AuthRepoImpl._requireEnvelope` in `lib/features/auth/data/repos/auth_repo_impl.dart`.

### Retry, rate limits, and cancellation

- **Idempotent GET** (lists, detail, categories): retry on `429` and `5xx` with bounded exponential backoff (for example 3 attempts: 500ms, 1s, 2s). Use an injectable `sleep` in tests.
- **Non-idempotent POST** (OTP verify, checkout): execute once; do not auto-retry success paths.
- **Search / autocomplete**: accept `CancelToken?`; cancelled requests must not surface as user-visible errors.
- Map `DioException` through `ServerFailure.fromDioException` unless the feature needs a typed failure (for example `AuthFailure`).

### Network and tenant configuration

- **Never hardcode** API base URLs in feature repos. Use `Dio` configured with `NetworkConfig.baseUrl` from `assets/config/*.json` (`app.apiBaseUrl`, `app.tenantSlug`).
- Resolve relative asset/image paths with `NetworkConfig.assetBaseUrl`.
- Multi-tenant public endpoints may require `X-Tenant-ID` even when no `Authorization` header is needed. Prefer tenant id from token storage after login; fall back to config when documented for that endpoint.
- Register `NetworkConfig` and `Dio` in `lib/core/utils/service_locator.dart` before repositories.

## 5. Model Responsibilities

Models should be resilient to backend changes.

Use `Equatable` and hand-written `fromJson` / `toJson` unless the project explicitly adopts code generation for that feature. Expose stable UI-facing getters (`name`, `image`, `price`) so JSON bindings and widgets never depend on raw backend keys.

For each model:
- Parse backend field names in `fromJson`.
- Normalize inconsistent field names into one consistent app-facing API.
- Expose compatibility getters when the UI still expects older field names.
- Keep `toJson` useful for caching, screen state, or dynamic rendering.

### Example pattern

- Backend may send `productId`, `titleAr`, `titleEn`, `primaryImageUrl`, `basePrice`.
- App-facing getters may expose `name`, `image`, `price`, and `currency`.

This keeps the UI stable while the backend evolves.

## 6. Cubit and State Rules

Cubits should only orchestrate data flow and state transitions.

### Cubit responsibilities

- Hold the current request state
- Call repository methods
- Emit loading, success, and failure states
- Handle pagination entry points such as `loadNextPage`

### State recommendations

For data-backed features, state should usually include:
- `requestKey`
- `isLoadMore` when pagination is supported
- success payload or error message

### Loading rules

- Initial page load should emit a full loading state.
- Load-more should emit a separate pagination state.
- The UI should be able to show a full-screen loader or a footer loader depending on the state.

## 7. Dynamic JSON Screen Rules

This project also supports JSON-driven pages in `assets/config/mobile_production_v2.json`.

When a page needs backend data:

- Add `data.requestKey` so the request can be tracked.
- Add `data.requestUrl` for the endpoint path.
- Add `data.page` and `data.size` when pagination is needed.
- Use `itemBuilder.source` to bind the rendered list/grid to `dataContext.requests.<requestKey>.data`.
- Use `valuePath` and `urlPath` for bindings inside the item template.

### JSON data contract pattern

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

### Item binding pattern

```json
"itemBuilder": {
  "type": "repeat",
  "source": "dataContext.requests.product-list.data",
  "item": {
    "type": "card",
    "child": {
      "type": "text",
      "props": {
        "valuePath": "item.name",
        "value": ""
      }
    }
  }
}
```

## 8. Engine Responsibilities

If the feature is driven by dynamic JSON, the engine may also need changes.

Update engine code when you need:
- new component rendering behavior
- new action types
- new binding paths
- dynamic image URL resolution
- route placeholder interpolation
- list pagination support

### Main engine files

- `lib/engine/screen_renderer/screen_renderer.dart`
  - Recursively builds the widget tree.
  - Passes context into action handlers and renderers.

- `lib/engine/requests/request_mapper.dart`
  - Collects request definitions from JSON.
  - Dispatches product requests for tracked data blocks.

- `lib/engine/actions/action_dispatcher.dart`
  - Handles tap actions like navigation and API calls.

- `lib/engine/tree/renderers/image_renderer.dart`
  - Resolves image source URLs.

- `lib/engine/tree/renderers/scaffold_renderer.dart`
  - Handles page-level scrolling and load-more behavior.

## 9. Dependency Registration

When adding a feature that uses repositories or cubits, register them in `lib/core/utils/service_locator.dart`.

Use the existing style:

- `registerLazySingleton` for repositories and shared services
- `registerFactory` for cubits that should be recreated per screen

Example:

```dart
getIt.registerLazySingleton<FeatureRepo>(
  () => FeatureRepoImpl(getIt<Dio>()),
);

getIt.registerFactory<FeatureCubit>(
  () => FeatureCubit(getIt<FeatureRepo>()),
);
```

## 10. Testing Requirements

Add tests under `test/features/<feature_name>/` for every new endpoint.

Minimum coverage:

- **Models:** `fromJson` happy path, missing optional fields, alternate backend key names.
- **Repositories:** envelope `success: false`, malformed `data`, HTTP errors, retry on 429/5xx where applicable, cancel handling for debounced search.
- **Cubits:** loading → success/failure, `requestKey`, `isLoadMore`, pagination guards (`hasNext`).

Use `FakeHttpClientAdapter` (see `test/features/auth/support/auth_test_utils.dart`) and a `Dio` instance with `NetworkConfig.defaultBaseUrl`. Inject `sleep` in repos that retry so tests stay fast.

## 11. Endpoint Checklist

Before merging a new endpoint, confirm:

- Repository methods return `Either<Failure, T>`.
- The API envelope is validated (`success`, `data` shape, `meta` when paginated).
- The repository parses the real backend payload shape.
- The model exposes stable UI-friendly getters.
- Pagination metadata is handled if the endpoint supports pages.
- The cubit exposes loading and error states for the screen.
- The feature is registered in the service locator.
- The UI is not depending on raw backend keys directly unless unavoidable.
- JSON-driven screens are updated if the endpoint powers a dynamic page.

## 12. Feature Checklist

Before merging a new feature, confirm:

- The feature folder follows the standard `data/` and `presentation/` split.
- State management lives in cubit files, not in widgets.
- API concerns stay out of view files.
- Model names are consistent across parsing, state, and UI.
- Errors are surfaced in a user-visible way.
- Any dynamic JSON blocks have matching request keys and bindings.
- **Post-implementation review** (§15) completed—not only “code compiles.”

## 13. Module Implementation Prompts

For large features with many endpoints, maintain a focused implementation prompt beside the feature (for example `lib/features/product/product_api_prompt.md`). The prompt must reference this guide and the feature API guide; it must not contradict folder layout or layer rules here.

## 14. Recommended Pattern for New Product-Like Features

Use this pattern for any list-based backend feature:

- Repository gets `page`, `size`, and optional filter parameters.
- Response model parses `data` plus `meta`.
- Cubit exposes `getItems`, `loadNextPage`, and `loadPreviousPage` only if needed.
- Screen listens to loading and appends data when `isLoadMore` is true.
- JSON config uses `requestKey` and `itemBuilder.source` to render items dynamically.

This is the preferred structure for future API-backed features in this app.

## 15. Post-Implementation Review (required before merge)

After coding is finished—and **before** opening or merging a PR—perform a deliberate review pass. Do not treat “tests pass” as sufficient on its own.

### When to run it

- At the end of every endpoint or feature task.
- At the end of each phased prompt (for example Prompt 1, then Prompt 2) when work is split across chats.
- Again after all phases are combined, before the final merge.

### What to review

**Correctness**

- Every planned endpoint exists on the repository contract and is implemented in the impl class.
- Real backend payload shapes are parsed (compare against the feature API guide, not assumptions).
- Envelope rules are applied consistently (`success`, `data` type, `meta` for paginated responses).
- Edge cases from the API guide are handled (empty lists, 404, cancelled search, partial `include` blocks).
- JSON-driven screens: `requestKey`, `requestUrl`, and `itemBuilder.source` paths match cubit state keys.

**Architecture & boundaries**

- No HTTP, parsing, or retry logic in widgets, renderers, or cubits beyond orchestration.
- No duplicate URL strings, magic strings, or copy-pasted envelope parsing—shared helpers live in the repo (or a small shared parser if multiple repos need it).
- Service locator registers **interfaces**, not only concrete impl types, where the project already follows that pattern.
- Engine changes are limited to dispatch and bindings; no feature business rules in renderers.

**Quality & maintainability**

- Remove dead code, commented-out experiments, and debug-only logs not using `AppLogger`.
- Prefer one clear code path over special-case branches that could be unified.
- Models expose stable UI getters; callers do not depend on raw backend field names.
- Names match existing feature conventions (files, classes, method params).

**Optimization (proportionate, not premature)**

- Avoid redundant API calls (double fetch on build, uncancelled search/autocomplete requests).
- Pagination appends or replaces data in one documented place (cubit or engine), not both inconsistently.
- Do not add caching, retries, or abstractions unless the API guide or this document calls for them.
- Do not introduce new packages or patterns (for example code generation) without project alignment.

### Review checklist

- [ ] Re-read `docs/ENDPOINTS_AND_FEATURES_GUIDE.md` sections relevant to this feature.
- [ ] Re-read the feature API guide sections for each endpoint touched.
- [ ] Walk through **Endpoint Checklist** (§11) and **Feature Checklist** (§12) line by line.
- [ ] Run `flutter analyze` on changed paths and `flutter test` for the feature test folder.
- [ ] Manually smoke-test JSON screens that use new `requestUrl` values, if applicable.
- [ ] Confirm no regressions in shared infrastructure (`NetworkConfig`, interceptors, service locator).
- [ ] If anything was deferred or hacked, document it in the PR description or fix it before merge.

### Outcome

The implementation is merge-ready only when the review finds **no open gaps** against the guides and checklists above. If the review reveals missing endpoints, wrong parsing, or layer violations, fix them in the same branch before moving to the next prompt or merging.