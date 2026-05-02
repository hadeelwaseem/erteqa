# SOOQ Merchant Architecture Overview

Last updated: 2026-04-14
Scope: Current implementation in `lib/`, `assets/config/`, and `pubspec.yaml`

This document is the architecture reference for onboarding and future analysis.
It focuses on system boundaries, runtime flow, and structural decisions rather than file-by-file details.

## 1. High-Level Architecture

### Overall architecture style
The project uses a hybrid architecture:
- Feature-oriented Flutter app structure inspired by Clean Architecture (`features`, `core`)
- Cubit/BLoC for state management
- A JSON-driven UI rendering engine (`engine`) for runtime-configured screens (MVP V2)

### Key design principles observed
- Separation of concerns between cross-cutting infrastructure (`core`), feature modules (`features`), and rendering engine (`engine`)
- Deterministic routing for variant screens (`/variant/:id`)
- Dependency registration via Service Locator (`get_it`)
- Recursive composition for dynamic component trees

### System boundaries
- App shell boundary:
  - App startup, localization, global providers, and routing (`main.dart`, `AppRouter`)
- Feature boundary:
  - Business-facing modules under `lib/features/*`
- Dynamic UI engine boundary:
  - JSON parsing + component rendering in `lib/engine`
- External integration boundary:
  - HTTP (`dio` via `ApiService`), local key-value storage (`shared_preferences`), secure token storage (`flutter_secure_storage`)

## 2. Project Structure Breakdown

### Core platform and cross-cutting
- `lib/core/cubits/`: global cubits (token, shared preferences, theme/base patterns)
- `lib/core/utils/`: DI, router, constants, app observer, API service, sizing
- `lib/core/errors/`, `lib/core/enums/`, `lib/core/widgets/`: shared primitives and app-wide conventions

### Feature modules
- `lib/features/homescreen/`: entry navigation for variant selection
- `lib/features/variantscreen/`: active dynamic-screen pipeline (repo + cubit + view)
- `lib/features/auth/`: partial/transitional module with significant commented behavior

### Dynamic rendering engine
- `lib/engine/screen_renderer/`: orchestrates screen tree rendering
- `lib/engine/component_renderer/`: renderer interface contract
- `lib/engine/tree/renderers/`: per-component rendering strategies (scaffold, column, row, container, text, button, card)
- `lib/engine/tree/parsers/`: JSON property conversion to Flutter types

### Config and assets
- `lib/config/`: in-memory config contracts (`ScreenConfig`, `ComponentConfig`, theme/layout models)
- `assets/config/*.json`: runtime UI variants (`classic`, `modern`, `experimental`, `dashboard`)

### Reusable/shared components
- Reusable rendering primitives in `engine/tree/renderers`
- Shared parsing utilities in `engine/tree/parsers/property_parsers.dart`
- Shared infra services and global cubits under `core`

## 3. Layered Architecture

The current practical layering is:

- Presentation Layer
  - Responsibility: UI rendering, navigation handling, user interaction state
  - Key components: `HomeScreen`, `VariantScreen`, feature cubits
  - Interaction: calls repositories (currently directly from cubits in active variant flow)

- Data Layer
  - Responsibility: load and parse data/config from assets or APIs
  - Key components: `AssetVariantRepository`, `AuthRepoImpl`, `ApiService`
  - Interaction: returns parsed data/config to presentation state managers

- Infrastructure Layer
  - Responsibility: framework setup and cross-cutting plumbing
  - Key components: `setupServiceLocator`, `AppRouter`, localization setup, token/prefs storage cubits
  - Interaction: bootstraps app and injects dependencies

- Engine/Config Layer
  - Responsibility: transform config trees into widget trees
  - Key components: `ScreenRenderer`, `ComponentRenderer`, `ComponentConfig`, `PropertyParsers`
  - Interaction: consumed by presentation to render dynamic screens

- Domain Layer (status)
  - Intended in Clean Architecture terms, but currently not explicitly implemented as a use-case layer in active flows

## 4. Data Flow

### Startup flow
1. App initializes Flutter bindings.SS
2. Service Locator registers shared dependencies.
3. Token and shared preferences cubits initialize persisted state.
4. Router is created using initial token state.
5. App runs with global providers and localization.

### Dynamic screen flow (`/variant/:id`)
1. Router extracts `id` from URL.
2. `VariantScreen` creates `VariantCubit` with `VariantRepository` and `variantId`.
3. Cubit emits loading and calls repository.
4. Repository loads `assets/config/{variantId}.json`.
5. Repository parses JSON into `ScreenConfig` + recursive `ComponentConfig` tree.
6. Cubit emits success with parsed config.
7. `ScreenRenderer.withPrimitives()` recursively maps each component type to a renderer.
8. Renderer-specific property parsing converts raw values into Flutter types.
9. Final widget tree is mounted.

### Text diagram

```text
User Route /variant/:id
        |
        v
GoRouter -> VariantScreen
        |
        v
VariantCubit(loadVariant)
        |
        v
AssetVariantRepository.loadVariant(id)
        |
        v
assets/config/{id}.json
        |
        v
ScreenConfig + ComponentConfig tree
        |
        v
ScreenRenderer (strategy map)
        |
        v
Primitive Renderers + PropertyParsers
        |
        v
Flutter Widget Tree
```

### State management approach
- Main approach: Cubit state machines with loading/success/failure states
- Global state: token/prefs via app-level providers
- Feature state: per-screen cubits (e.g., `VariantCubit`)

### API/data source interactions
- Variant UI uses local asset JSON files as source
- API service exists for remote calls and is wired into auth repository implementation

## 5. Key Design Patterns

- Service Locator
  - Where: `core/utils/service_locator.dart`
  - Why: central dependency registration and lazy singleton lifecycle

- Cubit/BLoC state pattern
  - Where: feature and core cubits
  - Why: explicit, testable UI state transitions

- Strategy pattern (renderer dispatch)
  - Where: `ScreenRenderer` + `ComponentRenderer` implementations
  - Why: each component type maps to isolated render logic

- Composite/recursive tree rendering
  - Where: `ComponentConfig` with child/children + recursive build in `ScreenRenderer`
  - Why: represent arbitrary nested layouts from config

- Parser utility pattern
  - Where: `PropertyParsers`
  - Why: centralize dynamic property conversion logic

## 6. Dependencies & Coupling

### External libraries and roles
- `flutter_bloc`: state management
- `go_router`: route composition + path parameter resolution
- `get_it`: dependency registration and retrieval
- `dio`: HTTP client abstraction in `ApiService`
- `easy_localization`: i18n bootstrap and delegates
- `shared_preferences`, `flutter_secure_storage`: local persistence
- `equatable`: value semantics for state/model objects

### Internal module dependency direction
- Presentation depends on Data + Engine + Core
- Repositories depend on Config/Core and external services
- Engine depends on Config + Core enums
- Infrastructure is consumed by app shell and features

### Tight coupling and risk points
- Cubit directly depends on repository in active variant flow (no explicit use-case/domain boundary)
- `ComponentConfig.properties` is `Map<String, dynamic>` (runtime-typed coupling)
- Button renderer has no action binding contract (`onPressed` placeholder)
- Global cubits are both in DI and app providers (multiple access pathways)

## 7. Scalability & Maintainability Analysis

### Strengths
- Clear top-level module partition (`core`, `features`, `engine`, `config`)
- Dynamic rendering architecture is extensible for new component types
- Deterministic variant routing and asset mapping simplify debugging
- Solid startup plumbing (DI, i18n, router)

### Potential bottlenecks
- Untyped config properties can increase runtime defects as component/property surface grows
- Missing explicit domain/use-case layer can cause business logic drift into cubits/repos
- Large commented sections increase cognitive load and maintenance risk

### Growth risks
- No schema/versioning strategy for JSON config evolution
- No first-class action/event system for dynamic components
- Inconsistent implementation maturity across features (variant active, auth partial)

## 8. Rules & Conventions

### Naming and routing conventions
- Variant route is page-id driven: `/variant/:id`
- Asset naming convention maps `id -> assets/config/{id}.json`
- Component `type` values are enum-name aligned (`GenericComponentType`)

### Folder structure conventions
- Feature modules follow `data/` + `presentation/` split
- Shared cross-cutting concerns live under `core/`
- Engine concerns isolated under `engine/`
- Config contracts live under `config/`

### Coding patterns observed
- Cubits represent async flows via explicit state classes
- Renderers remain single-responsibility per component type
- Property conversion logic centralized in parser helpers
- DI registration centralized in one setup function

## 9. Known Issues / Risks

- Missing explicit Domain/use-case layer in active flows
- Significant commented code in auth/state paths indicates transitional architecture
- Dynamic config lacks schema-level validation and strict typing
- Renderer failure modes are often silent fallbacks (harder root-cause analysis)
- Dynamic button interactivity is not integrated yet (`onPressed` no-op)
- API service has consistency issues (e.g., `delete` success path does not return data)

## 10. Recommended Improvements

### High priority
- Add explicit domain/use-case layer for active flows
  - Impact: clearer boundaries, easier testing, lower coupling
- Introduce JSON schema + validation pipeline for dynamic config
  - Impact: reduce runtime failures and improve config authoring confidence
- Implement action binding contract for dynamic components (especially buttons)
  - Impact: move from static layouts to interactive dynamic screens
- Resolve and either complete or remove heavily commented auth paths
  - Impact: reduce ambiguity and architectural drift

### Medium priority
- Replace `Map<String, dynamic>` component properties with typed per-component property models
  - Impact: stronger compile-time safety and better tooling support
- Standardize error handling across renderers/parsers/api layer
  - Impact: better observability and faster debugging
- Consolidate global state access pattern (prefer single access path)
  - Impact: reduce accidental misuse and hidden dependencies

### Low priority
- Track and remove truly unused dependencies in `pubspec.yaml`
  - Impact: lower maintenance overhead
- Add architecture decision records (ADRs) for major transitions (dynamic UI engine, auth roadmap)
  - Impact: long-term maintainability and team alignment

## Assumptions

- The JSON-driven engine is a deliberate strategic direction, not a short-lived experiment.
- The auth module is in transition and planned to be completed or replaced.
- The current document prioritizes implemented runtime paths over commented/planned code.
