# Dynamic Screens Refinement - Final Decisions

Scope: Dynamic screens only (Page = Screen), based on current high-level JSON and previous audit outputs.

---

## ✅ Confirmed Decisions

1. Keep server-driven screens.
- A high-level page payload such as pageId + pageName + content is sufficient to represent dynamic screens.

2. Keep Cubit.
- Cubit is valid and required for loading and exposing dynamic screen state.

3. Keep a screen-level model.
- A single typed page model is still needed at page level (for example: pageId, pageName, content).
- This is not component-level typing; it is only screen envelope typing.

4. Keep navigation by page identifier.
- Runtime navigation can remain pageId-driven (for example: /variant/:id or /page/:id).

5. Keep features folder.
- Dynamic UI does not remove the need for business capabilities organization.

---

## ⚠️ Adjustments

1. Simplify page-level requirements to only what is truly necessary now.
- Required now:
  - pageId (unique)
  - pageName (display/debug label)
  - content (high-level placeholder, still evolving)

2. Add only one bootstrap requirement for runtime navigation.
- Ensure there is a deterministic initial page source (for example a startup pageId from backend or local default).
- This is required for app startup predictability.

3. Avoid duplicate screen models.
- Use one canonical screen envelope model at this milestone.
- Do not maintain multiple parallel page wrappers unless a real integration need appears.

4. Keep current routing approach, but make page lookup explicit.
- Router resolves a pageId and passes it to one dynamic screen host.
- No new resolver/factory layers are required now.

5. Re-scope model-layer recommendation.
- Page-level model typing stays.
- Component-level model explosion is postponed until component schema is finalized.

---

## ❌ Removed / Rejected Suggestions

1. Full folder overhaul now (infrastructure/shared/dynamic_ui renaming).
- Rejected: high migration cost with no direct page-level value at this milestone.

2. Replace features with pages.
- Rejected: pages are runtime content; features are still the maintainable engineering boundary.

3. Mandatory domain/usecase layer for all features right now.
- Rejected for this milestone scope: valid long-term architecture, but not strictly required to stabilize dynamic screen handling now.

4. PageFactory + PageResolver + extra navigation layer as immediate requirement.
- Rejected: duplicates responsibility already handled by router + cubit + repository.

5. Mandatory Cubit per page (including static-like pages).
- Rejected: creates boilerplate and fake state.

6. Component-level changes in this milestone.
- Rejected as out of scope for this task:
  - Event dispatcher
  - Per-component typed configs
  - Component registry redesign
  - Per-component error boundaries
  - Component property parser redesign

---

## 📁 Final Structure Recommendation

Minimal recommendation: keep existing structure, apply only a small clarification for dynamic screens.

```text
lib/
  core/                    (keep)
  engine/                  (keep)
  config/                  (keep; page/screen envelope model lives here)
  features/                (keep)
    variantscreen/         (keep as dynamic screen host feature)
      data/                (page config loading)
      presentation/
        manager/           (cubit)
        views/             (dynamic screen host)
```

Optional naming cleanup (not mandatory now):
- variantscreen -> dynamic_screens

No additional top-level layers are required at this stage.

---

## ⚙️ Cubit Usage Rules

1. Use plain Cubit by default for dynamic screens.
- Screen loading and failure/success states are enough.

2. Use BaseCubit only when there is real repetition.
- Condition: 3+ cubits share identical loading/success/failure behavior.
- If this condition is not met, keep plain Cubit.

3. Do not create one Cubit per pageId.
- Use one dynamic screen cubit pattern that accepts pageId input.

4. Keep Cubit initialization simple.
- Cubit can load in constructor or explicit init method.
- Pick one style in the dynamic screen feature and stay consistent.

5. Keep Cubit responsibility limited.
- Cubit coordinates page loading and state emission.
- Do not force unrelated abstractions into the cubit layer.

---

## 🚫 Overengineering Fixes

1. Overengineering: introducing multiple new architecture layers now.
- Why: page-level objective is limited and JSON is still high-level.
- Simpler alternative: keep current folders and refine only dynamic screen feature boundaries.

2. Overengineering: enforcing full Clean Architecture migration before screen stability.
- Why: large migration unrelated to immediate page-level runtime needs.
- Simpler alternative: keep repository + cubit flow for dynamic screen loading in this milestone.

3. Overengineering: forcing abstract factories/resolvers early.
- Why: adds indirection without current complexity demand.
- Simpler alternative: route with pageId directly to a single dynamic host screen.

4. Overengineering: mandatory BaseCubit usage.
- Why: abstraction before repeated problem exists.
- Simpler alternative: plain Cubit first; introduce BaseCubit only for proven duplication.

5. Overengineering: component-level redesign inside a page-level milestone.
- Why: violates current scope and delays delivery.
- Simpler alternative: freeze component-level redesign until content schema is finalized.

---

## Assumption Audit

1. Invalid assumption: component schema is stable enough for deep component modeling now.
- Status: ❌ Invalid.
- Action: postpone component-level model expansion.

2. Invalid assumption: each page requires dedicated static folder/cubit.
- Status: ❌ Invalid for dynamic pages.
- Action: keep one dynamic screen host flow keyed by pageId.

3. Invalid assumption: features folder becomes unnecessary when screens are dynamic.
- Status: ❌ Invalid.
- Action: keep features for business/technical boundaries.

4. Invalid assumption: full domain/usecase rollout is mandatory immediately for this milestone.
- Status: ❌ Invalid for current scope.
- Action: treat as later architecture hardening task, not current blocker.

5. Invalid assumption: extra routing abstraction layers are required now.
- Status: ❌ Invalid.
- Action: keep routing minimal and explicit.

---

Result: Prior audit intent remains useful, but this milestone should stay strictly minimal and page-focused.