# RULES.md — SOOQ Merchant Engineering Standards

**Audience:** Human engineers, code reviewers, and AI assistants working in this repository.  
**Status:** Authoritative for *how* we build; [`AGENTS.md`](AGENTS.md) is the AI entry point; [`docs/ai/`](docs/ai/README.md) is deep reference.

---

## 0. Preamble

### 0.1 Purpose

This document defines **enforceable** engineering standards for the SOOQ Merchant Flutter repository: a **dynamic app generator** where merchant UI, navigation, and theme are driven by JSON (`assets/config/*.json`) and rendered by the engine (`lib/engine/`). Standards here are grounded in the existing codebase — not aspirational architecture that contradicts production code.

### 0.2 Relationship to other docs

| Document | Role | When to read |
|----------|------|--------------|
| [`AGENTS.md`](AGENTS.md) | AI entry: identity, decision tree, hard constraints, doc map | Start of every AI task |
| **This file (`RULES.md`)** | Long-form standards, examples, anti-patterns, mandatory checklist | Before coding; end of every task |
| [`.cursor/rules/sooqrules.mdc`](.cursor/rules/sooqrules.mdc) | Always-on short contract (injected in Cursor) | Automatic |
| [`.cursor/rules/*.mdc`](.cursor/rules/) | Path-scoped detail (`engine`, `config`, `core`, `features-*`) | When editing matching paths |
| [`docs/ai/`](docs/ai/README.md) | Layer guides, workflows, file index | Task-specific depth |
| [`docs/engine/builder-specs/`](docs/engine/builder-specs/README.md) | Website builder handoffs for JSON not in prod config | New engine JSON contracts |
| [`docs/engine/RENDERER_AUDIT_IMPLEMENTATION_PLAN.md`](docs/engine/RENDERER_AUDIT_IMPLEMENTATION_PLAN.md) | Phased engine/renderer work | Engine audit tasks |

**Do not trust for API truth:** `docs/_archive/`, stubbed `lib/features/*/README.md` guides. Ground truth for endpoints: `auth_repo_impl.dart`, `product_repo_impl.dart`, and JSON `requestUrl` values.

### 0.3 Rule precedence

When instructions conflict, apply this order (highest wins):

1. **Explicit user/task instructions** in the current conversation  
2. **`RULES.md`** (this file) — engineering standards and checklist  
3. **`.cursor/rules/sooqrules.mdc`** — always-on short contract  
4. **Scoped `.cursor/rules/*.mdc`** — path-specific (`engine.mdc`, `config.mdc`, …)  
5. **`docs/ai/*`** — reference detail (must not contradict layers or repos)

If scoped rules and `docs/ai` disagree with repo code, **code wins** — fix docs in a follow-up, do not invent behavior.

### 0.4 When to update which file

| Change type | Update |
|-------------|--------|
| New hard constraint or layer boundary | `RULES.md` §3, `sooqrules.mdc`, `AGENTS.md` (short) |
| New JSON prop/page/theme the engine reads, **not** in prod JSON | `docs/engine/builder-specs/<phase>-<slug>.md` + index |
| New JSON prop **in** prod config | `assets/config/mobile_production_v2.json` (when task allows) + optional `docs/ai/02-config-and-json.md` |
| New component `type` | Engine + `component_schemas.dart` + `docs/ai/03-engine.md` |
| New API path | Feature repo + `service_locator.dart` + `docs/ai/06-*` / `07-*` |
| Path-specific convention only | Relevant `.cursor/rules/*.mdc` |
| In-app user messages (`AppMessenger`) | `RULES.md` §3.10, `core.mdc`, `docs/ai/05-core.md` |

---

## 1. General development rules

These apply to any professional codebase, including SOOQ.

### 1.1 End-of-task code review (mandatory)

Before marking work complete, **review every line** you added or changed — not only the “main” file. Look for typos, wrong imports, copy-paste errors, and logic that only works on the happy path.

**Anti-pattern:** Changing `request_mapper.dart` but leaving a stale test that still asserts old URL resolution.

### 1.2 Preserve existing behavior

Do not break routes, parsers, or public contracts unless the user explicitly approves. Prefer additive changes (new optional props) over silent behavior changes.

**Anti-pattern:** Tightening validation so existing prod JSON pages fail to parse without a migration plan.

### 1.3 Reuse before inventing

Search the repo for existing parsers, cubits, failure types, and test utilities (`test/features/*/support/`). Extend them rather than parallel implementations.

**Anti-pattern:** Adding a second path resolver when `data_context_path.dart` already handles dotted paths.

### 1.4 DRY without premature abstraction

Extract helpers when the same non-trivial logic appears **twice** with the same semantics. Do not create abstraction layers for one call site “for later.”

### 1.5 Production-ready code

Handle failures explicitly: network errors, empty lists, invalid JSON shapes, missing `requestKey`. Avoid “works on my machine” assumptions (missing assets, wrong tenant).

### 1.6 SOLID and clean architecture (where applicable)

| Principle | SOOQ application |
|-----------|------------------|
| **S**ingle responsibility | Renderers layout-only; repos HTTP-only; `VariantScreen` orchestrates |
| **O**pen/closed | New `type` via new renderer + registry, not editing ten renderers |
| **L**iskov | `ComponentRenderer` implementations honor `ComponentConfig` contract |
| **I**nterface segregation | Feature repos expose narrow methods; cubits depend on interfaces |
| **D**ependency inversion | Engine depends on `dataContext`, not `ProductRepo` |

### 1.7 Edge cases and failure paths

Every repo method should have a Left path; every cubit should emit failure/empty states; list/grid should respect `request_ui_state` phases.

### 1.8 Minimal dependencies

Do not add packages to `pubspec.yaml` without need. No speculative utilities or unused exports.

### 1.9 Backward compatibility

Default new JSON props to safe behavior when absent. Do not rename JSON keys in Dart without builder-spec migration notes.

### 1.10 Readability and naming

Match surrounding files: `snake_case` files, `PascalCase` types, cubit/state naming `FeatureCubit` / `FeatureState`. Prefer clear names over comments explaining obscure abbreviations.

### 1.11 Hygiene

Remove dead code, unused imports, and commented-out blocks before finishing. Run analyzer on touched files when practical.

### 1.12 Null-safety and type-safety

Avoid `dynamic` casts without guards in new code. Prefer typed models in `lib/features/*/data/models/`.

### 1.13 Scope discipline

No drive-by refactors, formatting sweeps, or unrelated file edits. One task → one coherent diff.

### 1.14 Git

**Create commits only when the user explicitly asks.** Do not push unless asked.

---

## 2. Flutter and Dart rules

Traditional Flutter guidance, adapted for a JSON-driven runtime.

### 2.1 Widget composition

- Prefer small, focused widgets in **engine renderers** — one renderer file per `type`.
- Use `const` constructors where inputs are compile-time constant.
- Avoid rebuilding entire trees when only `dataContext` slice changed; `VariantScreen` should scope rebuilds via `BlocBuilder` on relevant cubits.

**Anti-pattern:** `setState` in a hand-built merchant screen for data that should flow through `dataContext`.

### 2.2 Bloc / Cubit lifecycle

| Rule | Detail |
|------|--------|
| **Scope** | Provide cubits at route/shell level via `BlocProvider` / `getIt` factories per `service_locator.dart` |
| **emit after dispose** | Guard async completions: check `isClosed` before `emit` |
| **Context** | Do not hold `BuildContext` in cubits; pass data via states |
| **UI subscription** | Use `BlocBuilder` / `BlocListener` in widgets — not manual cubit singletons in renderers |

**Anti-pattern:** `Future.delayed` then `emit` without `isClosed` check after user pops route.

### 2.3 Navigation (GoRouter)

- Routes come from `MobileAppConfig` via `AppRouter.setupRouter`.
- Dynamic pages: `VariantScreen(variantId, pageRoute, routeParams)`.
- Path params (`:productId`, `:slug`) live in `dataContext['routeParams']` for actions and mappers.
- `shellExcludeRoutes` in JSON lists routes outside tab shell (auth, splash, checkout, detail).

**Anti-pattern:** `Navigator.push` to a hardcoded `MaterialPageRoute` for a route that exists in JSON.

### 2.4 Theming

- **Source of truth:** JSON `theme` → `MobileThemeConfig` → `EngineTheme` in `dataContext`.
- Do **not** introduce a second full app theme in `main.dart` that overrides JSON tokens.
- `main.dart` may set system UI overlay; engine reads semantic colors from config.

### 2.5 Separation: UI vs business logic

| Concern | Location |
|---------|----------|
| Layout, tap wiring, path resolution | `lib/engine/` |
| HTTP, DTOs, validation rules | `lib/features/` |
| DI, interceptors, router | `lib/core/` |
| Declarative structure | `assets/config/*.json` |

**Critical for SOOQ:** Renderers never call `Dio` or feature repos.

### 2.6 Async

- Prefer `async`/`await` over unhandled `.then`.
- Propagate errors to cubit states → `dataContext['requests.{key}']` with `success: false`.
- Debounce search in cubit or feature layer, not in every keystroke rebuild.

### 2.7 Memory and resources

- Dispose `TextEditingController`, `ScrollController`, `AnimationController` in Stateful widgets (legacy views).
- Cancel `StreamSubscription` in `dispose`.
- Engine renderers should stay stateless where possible.

### 2.8 Performance

- Lists/grids: use engine `listView` / `gridView` with virtualization patterns already in renderers; avoid unbounded nested scrollables.
- Images: use `image` renderer URLs; cache via network layer conventions.
- Search: debounce autocomplete/query requests (mapper `qField` deferral pattern in `VariantScreen`).

### 2.9 Feature folder structure

```
lib/features/<domain>/
  data/
    models/
    repos/          # *Repo interface + *RepoImpl
  presentation/
    manager/        # *Cubit, *State
    views/          # legacy only — prefer JSON routes
```

### 2.10 Localization

- App uses `easy_localization` (`assets/translations/`).
- User-visible strings in JSON `props.value` are config-owned; framework strings use `.tr()` in core/legacy views.
- When adding engine Exposed copy, consider RTL (`ar` default locale in `main.dart`).

### 2.11 Accessibility

- When engine reads a11y props, follow [`docs/engine/builder-specs/10-accessibility-props.md`](docs/engine/builder-specs/10-accessibility-props.md): `semanticsLabel`, `accessibilityLabel`, `tap.semanticLabel`.
- Minimum tap targets and contrast should use theme tokens, not one-off hardcoded colors in renderers.

### 2.12 Forms

- JSON `form` + `textFormField` integrate with `FormStateStore` in `dataContext`.
- `tap` may set `requireValidForm` + `formId` — see `action_dispatcher.dart`.
- Autovalidate: [`06-form-autovalidate.md`](docs/engine/builder-specs/06-form-autovalidate.md) when adding `autovalidateMode`.

### 2.13 API integration

- **Only** feature repos call `Dio` (via `ApiService`).
- Repos return `Future<Either<Failure, T>>`.
- `AuthInterceptor` attaches tokens for protected routes; **public catalog** uses `/api/v1/public/*` **without** auth headers.

### 2.14 Pagination and list states

- JSON: `data.requestUrl`, `page`, `size`, `requestKey`.
- UI phases: `lib/engine/request_ui_state.dart` — loading, empty, error, ready.
- `dataContext` keys: `loadingRequestKeys`, `requests.{key}`, optional `emptyMessage` / `errorMessage` on components.

### 2.15 Logging and debug

- No secrets, tokens, or OTP in logs.
- Remove `print` / debug-only dumps before completing a task.
- `AppBlocObserver` is for development diagnostics — do not log PII in production builds.

---

## 3. SOOQ project-specific rules

### 3.1 Identity and JSON-first

| Fact | Implication |
|------|-------------|
| Flutter is the **runtime**, not the product definition | Merchant screens are not a forest of `StatelessWidget` pages |
| Active config | `mobile_production_v2` — `lib/main.dart` → `const _kActiveConfig = 'mobile_production_v2'` |
| Prod JSON | `assets/config/mobile_production_v2.json` |
| Default UI change | Edit JSON only; **ask** before new Dart screens |
| Multi-tenant | Same binary, different JSON variants — **no** `if (tenantSlug == 'x')` UI in Dart |

**Component dispatch:** Use `type` + `props` + `data` / `valuePath` / `urlPath`.  
**Never** use `semanticType` as a renderer registry key. `semanticType` is documentation/metadata (e.g. `ProductList` on a `gridView`).

**24 component types:**  
`scaffold`, `singleChildScrollView`, `column`, `row`, `container`, `listView`, `gridView`, `text`, `textFormField`, `form`, `button`, `card`, `spacer`, `image`, `appBar`, `divider`, `icon`, `richtext`, `videoPlayer`, `stack`, `imageSlider`, `timer`, `progressIndicator`, `unsupported`

Registry: `ScreenRenderer._createDefaultRenderers` in `lib/engine/screen_renderer/screen_renderer.dart`.

### 3.2 Layer boundaries

| Layer | Path | May | Must not |
|-------|------|-----|----------|
| **Config** | `lib/config/`, `assets/config/` | Data models, JSON assets | Flutter UI widgets, API calls |
| **Engine** | `lib/engine/` | Render trees, `tap` actions, request mapping, parsers, validation warnings | Domain rules, `import` feature repos/cubits in renderers, HTTP fetch |
| **Core** | `lib/core/` | DI (`service_locator.dart`), `Dio`, `AppRouter`, `TokenCubit`, `AppMessenger`, shared widgets | Parse page JSON, register renderers, product-specific API |
| **Features** | `lib/features/` | Repos, cubits, models, `VariantScreen` orchestration | Change renderer registry, hardcode merchant layouts |

**Hard rule:** No `lib/features/*` imports inside `lib/engine/tree/renderers/`.

### 3.3 Decision tree — where to change what

| Task | Where to change | Notes |
|------|-----------------|-------|
| Layout, copy, colors, spacing, nav labels | `assets/config/mobile_production_v2.json` | Primary merchant customization |
| New route / page | `pages[]` + `navigation` / `shellExcludeRoutes` in JSON | Router reads config |
| New visual primitive (`type`) | `GenericComponentType` + `lib/engine/tree/renderers/*` + `ScreenRenderer` + `component_schemas.dart` | Add tests under `test/engine/` |
| New API or domain rule | `lib/features/<domain>/` + `service_locator.dart` | Interface + impl + cubit |
| Wire list/grid to API | JSON `requestUrl` + `requestKey` → `EngineRequestMapper` → `VariantScreen` cubit wiring | Not renderer fetch |
| Button / card navigation | `"tap": { "type": "navigate", "route": "/path/:id" }` | `action_dispatcher.dart` |
| Auth / session | `lib/features/auth/` + `TokenCubit` + `AuthInterceptor` | OTP paths below |
| Theme tokens | JSON `theme` section | Consumed into `EngineTheme` |
| Loading / empty / error for requests | JSON messages + `request_ui_state` + `VariantScreen` `dataContext` | See §3.6 |
| Transient user message (validation, auth, success toast) | `AppMessenger` in `lib/core/feedback/app_messenger.dart` | See §3.10 — **not** `SnackBar` |

**Examples**

- *Move hero banner below categories* → reorder `children` in JSON, not new Dart screen.
- *Add wishlist API* → new feature module + mapper entry + `VariantScreen` handler + JSON `requestUrl`.
- *New `carousel` component* → new engine type (only if primitives cannot compose it).

### 3.4 Builder spec rule (website builder handoff)

When engine code reads a JSON field that merchants/builders must author:

1. **Grep** `assets/config/mobile_production_v2.json` for each new `props`, page, or `theme` key.
2. **If absent:** create `docs/engine/builder-specs/<phase>-<slug>.md` from [`_TEMPLATE.md`](docs/engine/builder-specs/_TEMPLATE.md).
3. **Update** [`docs/engine/builder-specs/README.md`](docs/engine/builder-specs/README.md) index table.
4. **Blocked** if contract is neither in prod JSON nor documented in builder-specs.
5. **Do not** add undeclared keys only in Dart parsers without spec or prod JSON.
6. **In-repo JSON edits** only when the task explicitly allows (e.g. Phase 3, 7 audit tasks).
7. **Existing handoffs:** `02-list-grid`, `05-high-traffic`, `06-form-autovalidate`, `08-page-scroll`, `10-accessibility-props`.

```powershell
Select-String -Path assets\config\mobile_production_v2.json -Pattern "yourNewProp"
```

### 3.5 API guardrails

| Area | Correct paths | Implementation |
|------|---------------|----------------|
| Customer OTP | `POST /api/v1/customer/auth/otp/request`, `POST /api/v1/customer/auth/otp/verify` | `auth_repo_impl.dart` |
| **Wrong** auth | `/api/v1/auth/otp/*` | Do not use |
| Public catalog | `/api/v1/public/products`, `.../search`, `.../autocomplete`, `.../categories`, `.../categories/{slug}/products`, `.../products/{slug}` | `product_repo_impl.dart` |
| Auth on catalog | None — public endpoints | Interceptor must not require token |

JSON `requestUrl` strings must match repo paths after placeholder resolution (`:slug`, query params). Verify in `EngineRequestMapper` tests when adding patterns.

### 3.6 Request UI and theme

**Runtime flow**

```
main() → AppConfigLoader.load(_kActiveConfig)
      → MobileAppConfig
      → setupServiceLocator(networkConfig from app)
      → AppRouter.setupRouter
      → VariantScreen
           → EngineRequestMapper.collectRequests
           → cubits fetch → dataContext['requests.{key}']
           → ScreenRenderer.withPrimitives().render(..., dataContext:)
```

**Request UI contract** (`request_ui_state.dart`):

| `dataContext` key | Purpose |
|-------------------|---------|
| `requests.{requestKey}` | Payload (`success`, `message`, `data`, …) |
| `loadingRequestKeys` | In-flight initial load |
| `initialRequestKeys` | Keys fired on page load |
| `loadingMoreRequests` | Pagination footer state |

List/grid phases: `none`, `loading`, `error`, `empty`, `ready` — driven by props `requestKey`, optional `emptyMessage` / `errorMessage`.

**Theme:** `MobileThemeConfig` from JSON → `EngineTheme` injected into `dataContext` for renderers (colors, typography, button variants).

### 3.7 Engine and renderer audit work

- Follow [`docs/engine/RENDERER_AUDIT_IMPLEMENTATION_PLAN.md`](docs/engine/RENDERER_AUDIT_IMPLEMENTATION_PLAN.md) one phase per task.
- Attach **only** phase-relevant slices from [`RENDERER_PRODUCTION_AUDIT.md`](docs/engine/RENDERER_PRODUCTION_AUDIT.md) — never the full audit in one prompt.
- Tests: `test/engine/renderers/`, `test/engine/actions/`, `test/engine/requests/` with **minimal** `ComponentConfig` trees — not full prod JSON file.
- **Phase 11:** sign-off / documentation only — **no new features**.

### 3.8 Safe feature modification

Before changing auth, product, or variant code:

1. Read `service_locator.dart` registrations (singleton vs factory).
2. Trace `VariantScreen` for how `requestKey` maps to cubits.
3. Confirm `EngineRequestMapper` still resolves URLs for new query/route params.
4. Run `flutter test` when touching engine, config models, or request wiring.

**Anti-pattern:** Adding `ProductCubit` usage in a renderer “just once” instead of extending `VariantScreen` data plumbing.

### 3.9 Project anti-patterns (minimum set)

| # | Anti-pattern | Why it fails |
|---|--------------|--------------|
| 1 | Hardcoded merchant `StatelessWidget` screens for flows available in JSON | Breaks generator model |
| 2 | `if (tenantSlug == 'acme')` UI branches | Use JSON variants instead |
| 3 | `Dio` / `ProductRepo` / cubits inside `lib/engine/tree/renderers/` | Violates layer boundaries |
| 4 | Parallel widget registry keyed on `semanticType` | Bypasses `ScreenRenderer` enum map |
| 5 | Parsing API JSON inside widgets or renderers | Belongs in repos + cubits |
| 6 | Trusting `docs/_archive/` for endpoint paths | Stale docs |
| 7 | Inventing `/api/v1/auth/otp` | Wrong customer auth prefix |
| 8 | Auth headers on `/api/v1/public/*` | Breaks public catalog contract |
| 9 | Fetching list data inside `listView`/`gridView` renderer | Use `VariantScreen` + `dataContext` |
| 10 | New JSON props only in Dart without builder-spec or prod JSON | Blocks website builder |
| 11 | Full-file widget tests against entire `mobile_production_v2.json` | Slow, brittle |
| 12 | Second app theme in `main.dart` overriding JSON | Split source of truth |
| 13 | `onTap` authored in JSON props | Runtime-injected from `tap` — see schemas |
| 14 | Drive-by refactors across `lib/features` when fixing engine bug | Review noise, regression risk |
| 15 | Git commit without user request | User workflow preference |
| 16 | `ScaffoldMessenger.showSnackBar` / bottom `SnackBar` for user feedback | Use `AppMessenger` (§3.10) — top overlay, single system |

### 3.10 In-app user messages (`AppMessenger`)

**Purpose:** One centralized API for **transient, top-of-screen** feedback — validation errors, API/cubit failures shown to the user, and success/info copy (e.g. OTP sent, login welcome, “order deleted”). This is **not** Firebase push notifications.

**Canonical implementation:** `lib/core/feedback/app_messenger.dart` — overlay at the top (slide-in card, auto-dismiss, tap to dismiss, single active message). Features call it with a `BuildContext`; do **not** duplicate overlay logic per feature.

**API shape (ground truth once implemented):**

| Export | Role |
|--------|------|
| `AppMessageKind` | `error`, `success`, `info`, `warning` |
| `AppMessage` | `kind`, `message`, optional `title`, `duration` |
| `AppMessenger.show(context, …)` | Generic entry |
| `AppMessenger.showError` / `showSuccess` / … | Convenience |
| `AppMessenger.dismiss()` | Clear active overlay |

**Styling:** Prefer `EngineTheme` from `dataContext` or `Theme.of(context)` (JSON `theme` — font family, `errorColor`, `surfaceColor`, `textColor`). Fallback: `lib/core/utils/constants.dart`. Do **not** hardcode fonts from other projects (e.g. Almarai).

**Must**

- Use `AppMessenger` for user-visible ephemeral messages from **features** (`BlocListener`, action handlers, cubit callbacks).
- Show **validation errors** the same way as auth/API errors (top card), e.g. `AuthFailureState` from `AuthCubit`.
- Keep implementation in **`lib/core/`** — no `lib/features/*` imports inside the messenger widget.
- Use **root overlay** (`rootNavigator` / `rootOverlay`) so messages work on auth routes without a JSON `scaffold`.
- `grep` before finishing: **zero** `ScaffoldMessenger.showSnackBar` / `SnackBar(` in `lib/`.

**Must not**

- Use Flutter **bottom** `SnackBar` or `ScaffoldMessenger.showSnackBar` for user messages.
- Call `AppMessenger` from `lib/engine/tree/renderers/` (layer violation).
- Duplicate list/grid **inline** request errors as top banners — those stay in `dataContext['requests.{key}']` + `request_ui_state.dart` unless the task explicitly wires global feedback for a user action.
- Add JSON `tap: { type: showMessage, … }` without **builder-spec** or prod JSON grep per §3.4.

**Integration points**

| Area | Pattern |
|------|---------|
| Auth | `_AuthRequestHost` in `variant_screen.dart` — listen to `AuthFailureState`, `AuthOtpRequested` (and optional welcome on `AuthAuthenticated`) |
| Form submit | `EngineActionDispatcher` — when `requireValidForm` fails, optional `AppMessenger.showError` (generic validation copy) |
| Future JSON-driven copy | New `showMessage` action only after `docs/engine/builder-specs/` handoff |

**Example**

```dart
AppMessenger.showError(context, errMessage, title: 'خطأ');
AppMessenger.showSuccess(context, 'تم تسجيل الدخول بنجاح، مرحباً $name');
```

Deep reference: [`docs/ai/05-core.md`](docs/ai/05-core.md#in-app-user-messages-appmessenger).

---

## 4. AI assistant and Cursor behavioral rules

### 4.1 Before coding

1. Read [`AGENTS.md`](AGENTS.md).
2. Read relevant [`docs/ai/`](docs/ai/README.md) chapters for the task layer.
3. If editing `lib/engine/**`, `lib/config/**`, etc., follow scoped `.mdc` rules.
4. Verify stack in `pubspec.yaml` and wiring in `service_locator.dart` — do not assume Redux, Riverpod, or GetX.

### 4.2 During implementation

- **Minimal diffs** — only files required for the task.
- **Reuse** existing parsers, failures, test support utilities.
- **State assumptions** explicitly when prod JSON cannot be read (e.g. “assuming `requestKey` X exists”).
- **Explain risky changes** — behavior changes, new required props, migration needs.
- **JSON-first** — propose JSON edits before new Dart UI.
- **Builder spec** — run grep procedure for every new engine-read JSON field.

### 4.3 Before finishing

- Complete [§5 Final validation checklist](#5-final-validation-checklist-mandatory) mentally and fix gaps.
- Run `flutter test` when touching `lib/engine/`, `lib/config/`, or request/action wiring.
- Run `dart analyze` on touched libraries when feasible.
- Do **not** create git commits unless the user asked.

### 4.4 Documentation pointers

When changing public contracts, update the smallest doc set:

- New `type` → `docs/ai/03-engine.md` + workflow in `09-workflows.md` if non-trivial  
- New API → `docs/ai/06-feature-auth.md` or `07-feature-product.md`  
- New JSON-only UI → optionally `02-config-and-json.md`  
- Engine-read prop not in prod → builder-spec only  
- User messages / `AppMessenger` → `docs/ai/05-core.md` + §3.10  

---

## 5. Final validation checklist (mandatory)

Complete this checklist at the end of **every** task before reporting done:

- [ ] All added/changed code reviewed line-by-line  
- [ ] No duplicated logic; no unused imports  
- [ ] Layer boundaries respected (no feature imports in renderers)  
- [ ] JSON-first respected (or explicit user approval for Dart UI)  
- [ ] Builder spec rule satisfied for new JSON contracts  
- [ ] Error / loading / empty states handled where applicable  
- [ ] Transient user messages use `AppMessenger` (§3.10), not `SnackBar`  
- [ ] Cubit lifecycle safe; no emit-after-dispose  
- [ ] API paths match guardrails; `requestUrl` aligned with repos  
- [ ] `semanticType` not used as renderer dispatch  
- [ ] Null safety; analyzer clean on touched files (`dart analyze` if run)  
- [ ] `flutter test` run (and pass) for engine/config changes  
- [ ] No debug noise left; no secrets logged  
- [ ] Existing routes/screens still work  
- [ ] Naming matches project conventions  
- [ ] Documentation pointers updated if public contracts changed  

---

## Appendix A — Active runtime reference

| Item | Value |
|------|-------|
| Entry | `lib/main.dart` |
| Config loader | `lib/engine/app_config_loader.dart` |
| DI | `lib/core/utils/service_locator.dart` |
| Router | `lib/core/utils/app_router.dart` |
| Page host | `lib/features/variantscreen/presentation/views/variant_screen.dart` |
| Page JSON | `lib/features/variantscreen/data/repos/variant_repository.dart` |
| Renderer | `lib/engine/screen_renderer/screen_renderer.dart` |
| Actions | `lib/engine/actions/action_dispatcher.dart` |
| Requests | `lib/engine/requests/request_mapper.dart` |
| Schemas | `lib/engine/validation/component_schemas.dart` |
| User messages | `lib/core/feedback/app_messenger.dart` |

## Appendix B — Tests

```bash
flutter test
```

See [`docs/ai/11-testing.md`](docs/ai/11-testing.md) for layout and patterns.

## Appendix C — Cursor rules index

| File | Scope |
|------|-------|
| `sooqrules.mdc` | Always apply — short contract |
| `config.mdc` | `lib/config/**`, `assets/config/**` |
| `engine.mdc` | `lib/engine/**` |
| `core.mdc` | `lib/core/**` |
| `features-auth.mdc` | `lib/features/auth/**` |
| `features-product.mdc` | `lib/features/product/**` |
| `features-variant.mdc` | `lib/features/variantscreen/**` |

---

*Last aligned with repo: `mobile_production_v2`, 20 renderers, customer OTP + public catalog paths as implemented in feature repos.*
