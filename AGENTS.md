# AGENTS.md — SOOQ Merchant Mobile

Instructions for AI assistants working in this repository. **Read this file first.** Deep reference: [`docs/ai/README.md`](docs/ai/README.md).

---

## Project identity

This is a **Flutter-based dynamic mobile app generator**, not a traditional Flutter app.

- Applications, screens, components, and themes are **defined as JSON data** (`assets/config/*.json`).
- Flutter is the **runtime rendering platform** only.
- One codebase generates merchant-specific experiences via configuration — **no per-merchant UI branching in Dart**.

---

## Architectural layers (strict boundaries)

| Layer | Path | May do | Must not |
|-------|------|--------|----------|
| **Config** | `lib/config/` | Pure data models | Flutter UI, API calls |
| **Engine** | `lib/engine/` | JSON → widgets, actions, request mapping | Business/domain logic |
| **Core** | `lib/core/` | DI, network, router, shared widgets | JSON parsing, template logic |
| **Features** | `lib/features/` | Repos, cubits, domain APIs | Change UI generation / renderer registry |

**Violations:** business logic in renderers; hardcoded merchant screens; duplicated UI per tenant.

---

## Active runtime

| Item | Value |
|------|-------|
| Config variant | `mobile_production_v2` (`lib/main.dart` → `_kActiveConfig`) |
| Config file | `assets/config/mobile_production_v2.json` |
| Entry flow | `AppConfigLoader` → `MobileAppConfig` → `setupServiceLocator` → `AppRouter` → `VariantScreen` → `ScreenRenderer` |

```
JSON (assets/config) → MobileAppConfig + page slice → ScreenConfig
  → EngineRequestMapper → Feature cubits → dataContext
  → ScreenRenderer (20 component types) → Flutter UI
```

---

## Decision tree

| Task | Where to change |
|------|-----------------|
| Change layout, copy, colors, navigation | `assets/config/mobile_production_v2.json` |
| New page/route | `pages[]` + `navigation` in JSON |
| New visual primitive (new `type`) | `GenericComponentType` + renderer + `ScreenRenderer` registry |
| New API / business logic | `lib/features/<domain>/data` + cubit + `service_locator.dart` |
| Wire API to JSON list/grid | `requestUrl` in JSON + `EngineRequestMapper` + `VariantScreen` |
| Button navigation | `tap: { type: navigate, route }` in JSON |
| Auth/session | `lib/features/auth/` + `TokenCubit` / `AuthInterceptor` |

**Default assumption:** UI changes are JSON-only. Ask before adding new Dart screens.

---

## Hard constraints (non-negotiable)

1. Do **not** hardcode screens, flows, or layouts for merchant features.
2. Do **not** embed product/auth/catalog logic in `lib/engine/tree/renderers/`.
3. Do **not** treat `semanticType` as a renderer key — use `type` + primitives + `data` binding.
4. Do **not** add `if (tenantSlug == 'x')` UI branches.
5. Public catalog uses `/api/v1/public/*` without auth headers.
6. Customer auth uses `/api/v1/customer/auth/otp/*`.

---

## Component types (quick reference)

`scaffold`, `singleChildScrollView`, `column`, `row`, `container`, `listView`, `gridView`, `text`, `textFormField`, `form`, `button`, `card`, `spacer`, `image`, `appBar`, `divider`, `icon`, `richtext`, `videoPlayer`, `unsupported`

Details: [`docs/ai/03-engine.md`](docs/ai/03-engine.md)

---

## Key files

| Purpose | File |
|---------|------|
| App entry | `lib/main.dart` |
| DI | `lib/core/utils/service_locator.dart` |
| Router | `lib/core/utils/app_router.dart` |
| Dynamic page host | `lib/features/variantscreen/presentation/views/variant_screen.dart` |
| JSON page parser | `lib/features/variantscreen/data/repos/variant_repository.dart` |
| Renderer (20 types) | `lib/engine/screen_renderer/screen_renderer.dart` |
| Actions | `lib/engine/actions/action_dispatcher.dart` |
| Requests | `lib/engine/requests/request_mapper.dart` |
| Product API | `lib/features/product/data/repos/product_repo_impl.dart` |
| Auth API | `lib/features/auth/data/repos/auth_repo_impl.dart` |

---

## Documentation map

| Doc | Topic |
|-----|-------|
| [docs/ai/00-overview.md](docs/ai/00-overview.md) | Glossary, non-goals |
| [docs/ai/01-architecture.md](docs/ai/01-architecture.md) | Layers, data flow |
| [docs/ai/02-config-and-json.md](docs/ai/02-config-and-json.md) | JSON schema |
| [docs/ai/03-engine.md](docs/ai/03-engine.md) | Renderers |
| [docs/ai/04-actions-and-requests.md](docs/ai/04-actions-and-requests.md) | tap + API binding |
| [docs/ai/05-core.md](docs/ai/05-core.md) | DI, network, router |
| [docs/ai/06-feature-auth.md](docs/ai/06-feature-auth.md) | OTP auth |
| [docs/ai/07-feature-product.md](docs/ai/07-feature-product.md) | Catalog APIs |
| [docs/ai/08-feature-variant-shell.md](docs/ai/08-feature-variant-shell.md) | Dynamic pages |
| [docs/ai/09-workflows.md](docs/ai/09-workflows.md) | How-to guides |
| [docs/ai/10-file-index.md](docs/ai/10-file-index.md) | Full file map |
| [docs/ai/11-testing.md](docs/ai/11-testing.md) | Tests |
| [docs/ai/12-production-status.md](docs/ai/12-production-status.md) | Gaps vs implemented |

---

## Do / Don't for AI

| Do | Don't |
|----|-------|
| Edit JSON for UI changes | Create new `StatelessWidget` screens for merchant flows |
| Use existing repos/cubits | Call `Dio` from renderers |
| Register new types in `ScreenRenderer` | Add parallel widget registry strings |
| Return `Either<Failure, T>` from repos | Parse API JSON in widgets |
| Match `requestUrl` to repo paths | Invent `/api/v1/auth/otp` (use `customer/auth`) |
| Read `docs/ai/` for details | Trust archived `docs/_archive/` or stubbed feature guides |

---

## Tests

```bash
flutter test
```

Patterns: [`docs/ai/11-testing.md`](docs/ai/11-testing.md)

---

## Cursor rules

Scoped rules in `.cursor/rules/` auto-attach by file path. Always-on: `sooqrules.mdc`.
