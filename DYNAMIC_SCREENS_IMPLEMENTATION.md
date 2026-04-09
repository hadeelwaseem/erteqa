# Dynamic Screens Implementation Guide

**Date**: April 9, 2026  
**Scope**: Implementation of dynamic screens refinement decisions  
**Based on**: DYNAMIC_SCREENS_REFINEMENT_FINAL.md  

---

## Overview

This document provides implementation guidelines and Cubit usage rules for the dynamic screens system. It is the source of truth for developers implementing or maintaining dynamic screen features.

---

## Screen Model Structure

### ScreenConfig (Minimal Envelope)

Located in: [lib/config/screen_config.dart](lib/config/screen_config.dart)

```dart
class ScreenConfig {
  final String pageId;        // Unique page identifier (used for navigation)
  final String pageName;      // Human-readable display name (debug/UI labels)
  final ComponentConfig root; // Root component tree (content envelope)
}
```

**Design Rationale**:
- **Minimal**: Only fields strictly necessary for dynamic pages.
- **Semantic**: `pageId` clarifies that this is the page's unique identity.
- `pageName` enables debugging and future UI features (e.g., breadcrumbs, titles).
- `root` is the component tree representing the page's dynamic content (the content envelope).

**No component-level typing** is done at this layer. Component details are handled by `ComponentConfig` and the rendering engine. This separation keeps the screen model stable while component schema evolves.

---

## Routing: Deterministic Page Resolution

### Route Pattern

```
GoRoute(
  path: '/variant/:id',
  builder: (context, state) {
    final pageId = state.pathParameters['id'] ?? 'classic';
    return VariantScreen(variantId: pageId, ...);
  },
)
```

### Flow

1. **User navigates**: `/variant/:pageId` (e.g., `/variant/dashboard`)
2. **Router extracts**: `pageId` from path parameters
3. **VariantScreen receives**: `pageId` as input
4. **VariantCubit loads**: `VariantCubit(repo, pageId).loadVariant()`
5. **Repository fetches**: JSON config from `assets/config/{pageId}.json`
6. **Config is parsed**: Into `ScreenConfig` (pageId, pageName, root)
7. **Cubit emits**: `VariantSuccess(config)`
8. **Screen renders**: Via `ScreenRenderer.withPrimitives().render(config)`

### Why This Is Deterministic

- **Page lookup is explicit**: No hidden factory layers or resolver patterns.
- **One entry point**: All dynamic screens go through the same route `/variant/:id`.
- **Stateless resolution**: Same `pageId` always resolves to the same JSON config.

### Bootstrap Strategy (Startup Page)

On app startup, determine the initial page to load:

**Option A: Backend-driven (Recommended)**
- Call a `ConfigService.getStartupPage()` from backend
- Fallback to a hardcoded default (e.g., `'classic'` or `'dashboard'`) if service unavailable
- Store result in `SharedPreferences` for session recall
- Navigate to `/variant/:startupPageId`

**Option B: Local default (Simplest)**
- Hardcode `'dashboard'` or `'classic'` as the initial page
- Navigate to `/variant/dashboard` on app startup

**Option C: Session-driven (Balanced)**
- Check `SharedPreferences` for last viewed page
- Fallback to hardcoded default if none found
- Navigate to that page on startup

**Current implementation**: See [lib/core/utils/app_router.dart](lib/core/utils/app_router.dart) for routing setup. Bootstrap logic can be added during app initialization (e.g., in `main.dart` or `AppRouter.setupRouter()`).

---

## Cubit Usage Rules

### Why Plain Cubit (Not BaseCubit)

`VariantCubit` extends plain `Cubit<VariantState>` because:

1. **Simple responsibility**: Load a single screen by pageId, emit success/failure states.
2. **Unique pattern**: Takes `pageId` as input, not suitable for generic base class.
3. **No premature abstraction**: `BaseCubit` is introduced only when 3+ cubits share identical behavior.

### VariantCubit Pattern

**Location**: [lib/features/variantscreen/presentation/manager/variant_cubit/variant_cubit.dart](lib/features/variantscreen/presentation/manager/variant_cubit/variant_cubit.dart)

```dart
class VariantCubit extends Cubit<VariantState> {
  VariantCubit(this._repo, this._variantId) : super(VariantInitial()) {
    loadVariant();
  }

  final VariantRepository _repo;
  final String _variantId;

  Future<void> loadVariant() async {
    emit(VariantLoading());
    try {
      final config = await _repo.loadVariant(_variantId);
      emit(VariantSuccess(config));
    } catch (e) {
      emit(VariantFailure(e.toString()));
    }
  }
}
```

**Responsibilities**:
- Accept `pageId` (_variantId) on construction
- Trigger load on construction (automatic initialization)
- Emit three states: `VariantLoading`, `VariantSuccess(config)`, `VariantFailure(message)`

**States**:
- `VariantInitial`: Starting state
- `VariantLoading`: Loading config from repository
- `VariantSuccess`: Config loaded successfully
- `VariantFailure`: Config load failed with error message

### Cubit Initialization (Simple)

Cubit is initialized inline in `VariantScreen`:

```dart
BlocProvider(
  create: (context) => VariantCubit(variantRepository, variantId),
  child: ...,
)
```

**Why simple initialization**:
- No need for complex builder patterns
- One Cubit instance per VariantScreen
- `variantId` is passed directly; no factory layers

### One Cubit Per Screen (Not Per PageId)

**Rule**: Create one `VariantCubit` instance per `VariantScreen` widget, keyed by `pageId`.

**Incorrect** (DO NOT DO):
```dart
// ❌ Creating one Cubit per pageId is unnecessary and wasteful
cubits['dashboard'] = VariantCubit(repo, 'dashboard');
cubits['classic'] = VariantCubit(repo, 'classic');
// ... etc
```

**Correct** (DO THIS):
```dart
// ✓ One Cubit instance per VariantScreen, initialized with the pageId
VariantCubit(repo, pageId)
```

### When to Consider BaseCubit

Introduce `BaseCubit` **only** when this condition is met:
- **3+ cubits** share identical loading/success/failure pattern AND
- The pattern cannot be reused via composition or simple inheritance

Current status: `VariantCubit` is the only dynamic screen cubit. `BaseCubit` is not yet needed.

### Scaling the Pattern

If `VariantScreen` needs to be nested or reused in multiple contexts, the pattern still holds:
- Pass `pageId` to each `VariantCubit` instance
- Each instance manages its own state independently
- No shared Cubit cache or factory required

---

## Data Layer: Repository

### VariantRepository Interface

**Location**: [lib/features/variantscreen/data/repos/variant_repository.dart](lib/features/variantscreen/data/repos/variant_repository.dart)

```dart
abstract class VariantRepository {
  Future<ScreenConfig> loadVariant(String pageId);
}
```

**Responsibility**: Load and parse screen config from source (currently: JSON assets).

### AssetVariantRepository Implementation

Loads JSON from `assets/config/{pageId}.json`:

```dart
class AssetVariantRepository implements VariantRepository {
  static const _configPath = 'assets/config';

  Future<ScreenConfig> loadVariant(String pageId) async {
    final jsonString = await rootBundle.loadString(
      '$_configPath/$pageId.json',
    );
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    return _parseScreenConfig(json);
  }

  ScreenConfig _parseScreenConfig(Map<String, dynamic> json) {
    final pageId = json['id'] as String;
    final pageName = json['pageName'] as String?;
    final rootJson = json['root'] as Map<String, dynamic>;
    final root = _parseComponentConfig(rootJson);
    return ScreenConfig(
      pageId: pageId,
      pageName: pageName ?? pageId, // Fallback if pageName not in JSON
      root: root,
    );
  }
}
```

**Parsing rules**:
- Extract `pageId` from JSON `id` field (required)
- Extract `pageName` from JSON `pageName` field (optional; fallback to `pageId`)
- Extract `root` component tree and recursively parse
- Return fully-formed `ScreenConfig`

### JSON Config Format

Each config file should follow this structure:

```json
{
  "id": "pageId",
  "pageName": "Display Name",
  "root": {
    "type": "scaffold",
    "backgroundColor": "#FFFFFF",
    "child": { ... }
  }
}
```

**Fields**:
- `id` (string, required): Unique page identifier
- `pageName` (string, optional): Display name; fallback is `id`
- `root` (object, required): Root component tree

**Current configs**: `classic.json`, `dashboard.json`, `experimental.json`, `modern.json` in `assets/config/`

---

## Presentation Layer: Views

### VariantScreen

**Location**: [lib/features/variantscreen/presentation/views/variant_screen.dart](lib/features/variantscreen/presentation/views/variant_screen.dart)

```dart
class VariantScreen extends StatelessWidget {
  const VariantScreen({
    required this.variantId,
    required this.variantRepository,
  });

  final String variantId;
  final VariantRepository variantRepository;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => VariantCubit(variantRepository, variantId),
      child: SafeArea(
        child: Scaffold(
          body: BlocBuilder<VariantCubit, VariantState>(
            builder: (context, state) {
              return switch (state) {
                VariantInitial() || VariantLoading() => const Center(
                  child: CircularProgressIndicator(),
                ),
                VariantSuccess(:final config) =>
                  ScreenRenderer.withPrimitives().render(config),
                VariantFailure(:final message) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(message, textAlign: TextAlign.center),
                  ),
                ),
              };
            },
          ),
        ),
      ),
    );
  }
}
```

**Responsibilities**:
- Act as the dynamic screen host
- Receive `pageId` (variantId) from router
- Create Cubit with `pageId`
- Render based on Cubit state:
  - Loading: Show progress indicator
  - Success: Render config via `ScreenRenderer`
  - Failure: Show error message

---

## Rendering Engine

### ScreenRenderer

**Location**: [lib/engine](lib/engine) (not detailed here; see engine docs)

The rendering engine handles:
- Component tree traversal
- Component type resolution (scaffold, column, row, text, button, etc.)
- Runtime property binding
- Widget construction

**Current call**: `ScreenRenderer.withPrimitives().render(config)` takes `ScreenConfig` and returns a Flutter widget tree.

**Note**: Component-level model changes are deferred to later milestones when component schema is finalized.

---

## Prevented Patterns (Antipatterns)

### ❌ DO NOT: Multiple Cubit Instances Per PageId

```dart
// Wrong: Creates unnecessary cache layer
final cubits = <String, VariantCubit>{};
cubits['dashboard'] ??= VariantCubit(repo, 'dashboard');
```

✅ **Correct**: One instance per screen load
```dart
VariantCubit(repo, pageId)
```

### ❌ DO NOT: Abstract Factory for Page Resolution

```dart
// Wrong: Adds indirection without current demand
class PageFactory {
  ScreenConfig resolve(String pageId) { ... }
}
```

✅ **Correct**: Direct repository lookup
```dart
VariantCubit(repo, pageId) // repo.loadVariant(pageId)
```

### ❌ DO NOT: Mandatory Cubit Per Page Type

```dart
// Wrong: Creates boilerplate for quasi-static pages
class DashboardCubit extends Cubit { ... }
class ClassicCubit extends Cubit { ... }
```

✅ **Correct**: Single Cubit handling all pages dynamically
```dart
class VariantCubit extends Cubit { ... } // Handles all pages
```

### ❌ DO NOT: Nested Dynamic Screens Without Thought

```dart
// Risky: Multiple Cubit layers can complicate state management
VariantScreen(
  variantId: 'dashboard',
  child: VariantScreen(variantId: 'nested-page'),
)
```

✅ **Current approach**: One dynamic screen per route; nesting is content-driven
```dart
// If nesting is needed, handle via component tree (content), not route
VariantScreen(variantId: 'dashboard') // Has nested components in JSON
```

### ❌ DO NOT: Component-Level Type Safety Now

```dart
// Wrong: Premature modeling of component props
class ButtonConfig { ... }
class TextConfig { ... }
class CardConfig { ... }
```

✅ **Current approach**: Generic ComponentConfig with dynamic properties
```dart
class ComponentConfig {
  GenericComponentType type;
  Map<String, dynamic> properties; // Dynamic; schema TBD
}
```

---

## Features Folder Organization

**Location**: [lib/features](lib/features)

```
features/
├── auth/                 (Authentication, onboarding)
├── homescreen/           (Main home/dashboard)
└── variantscreen/        (Dynamic screen host)
    ├── data/
    │   ├── models/       (No additional models; uses ScreenConfig)
    │   └── repos/        (VariantRepository)
    ├── presentation/
    │   ├── manager/      (VariantCubit)
    │   └── views/        (VariantScreen)
```

**Design**:
- Features remain the organizational boundary (not replaced by pages)
- `variantscreen` is the feature that hosts all dynamic pages
- No per-page static features needed; pages are data-driven

---

## Verification Checklist

Use this checklist to verify implementation alignment:

- [ ] **ScreenConfig model** has `pageId`, `pageName`, `root` fields
- [ ] **VariantRepository** parses JSON to extract all fields with fallbacks
- [ ] **JSON configs** include `id` and (optionally) `pageName`
- [ ] **VariantCubit** is plain Cubit with simple init + loadVariant()
- [ ] **VariantScreen** renders via one Cubit instance, no factory layers
- [ ] **Router** has explicit `/variant/:id` → VariantScreen(pageId)
- [ ] **No duplicate models**: ScreenConfig is canonical
- [ ] **Bootstrap strategy** documented (backend/local/session)
- [ ] **No unnecessary abstractions**: No PageFactory, PageResolver, etc.
- [ ] **Features folder** remains organizational boundary

---

## Future Considerations

1. **Bootstrap service**: Implement ConfigService for backend-driven startup page
2. **Component schema finalization**: When schema stabilizes, add component-level types
3. **Performance**: Consider caching strategies if many pages are loaded in a session
4. **Error handling**: Enhance with retry logic or offline support as needed
5. **BaseCubit introduction**: If 3+ similar cubits emerge, introduce BaseCubit
6. **Nested screens**: If needed, revisit current pattern with proper state isolation

---

## Related Documents

- [DYNAMIC_SCREENS_REFINEMENT_FINAL.md](DYNAMIC_SCREENS_REFINEMENT_FINAL.md) — Design decisions and rationale
- [lib/config/screen_config.dart](lib/config/screen_config.dart) — Model implementation
- [lib/features/variantscreen](lib/features/variantscreen) — Feature implementation
- [lib/engine](lib/engine) — Rendering engine (component rendering logic)

---

**Last Updated**: April 9, 2026  
**Author**: Architecture Team  
**Status**: Approved (Milestone 1 - Dynamic Screens Refinement)
