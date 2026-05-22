# Builder spec: Navigation type (push vs clear stack)

> **Phase:** Navigation phases 2–5  
> **Status:** `ready-for-builder`  
> **Active config:** `mobile_production_v2`  
> **Created:** 2026-05-22  

---

## Summary

The mobile engine supports optional **`navigation_type`** on JSON actions with `"type": "navigate"`. It controls whether the app uses GoRouter **`context.push`** (stacked route, AppBar back works) or **`context.go`** (replace stack / “clear stack”). The website builder must be able to author this field on **node `tap`**, **`cubitCall` `onSuccess` / `onFailure`**, and **timer `tap`** navigate actions.

---

## Gap vs production JSON

**Checked in** `assets/config/mobile_production_v2.json`:

| Item | Exists in prod JSON? | Evidence |
|------|----------------------|----------|
| `navigation_type` on navigate actions | Partial | `Select-String -Pattern "navigation_type"` — **1** match (line ~3574) |
| Navigate taps without `navigation_type` | Yes (default) | `"type": "navigate"` — **37** matches; omitted field → `clear_stack` / `go` |
| `cubitCall` `method: "logout"` | Yes | `settings-logout` node ~3567–3576 |

---

## Builder requirements

### 1. Navigate action — `navigation_type`

**Applies to:** any action object with `"type": "navigate"`:

- Component/node **`tap`**
- **`cubitCall`** nested **`onSuccess`** / **`onFailure`**
- **`timer`** **`tap`** (full action map)

**JSON shape (authoritative):**

```json
{
  "type": "navigate",
  "route": "/product/details/:productId",
  "navigation_type": "push"
}
```

| Field | Type | Required | Default (mobile) | Description |
|-------|------|----------|------------------|-------------|
| `type` | string | yes | — | Must be `navigate` |
| `route` | string | yes | — | Path; supports `:param` placeholders |
| `navigation_type` | string | no | `clear_stack` (`context.go`) | Stack behavior (see alias table) |
| `requireValidForm` | bool | no | false | Validate `formId` before dispatch |
| `formId` | string | no | — | Form id when `requireValidForm` is true |

**`navigation_type` values** (case-insensitive; trim whitespace):

| Author value | Aliases | Mobile API | Use when |
|--------------|---------|------------|----------|
| _(omit)_ | — | `context.go` | Default — auth success, splash, logout landing, tab-like flows |
| `clear_stack` | `clearstack`, `reset`, `go` | `context.go` | Same as omit — reset navigation stack |
| `push` | `stack` | `context.push` | Drill-down (e.g. list → product detail); user can go back via AppBar |

Unknown values → treated as `clear_stack`.

**Validation rules for builder:**

- Only valid on `type: navigate` (not on `apiCall` / `cubitCall` root).
- `route` must match a `pages[].route` or dynamic pattern the app registers (e.g. `/product/details/:productId`).
- For list/card taps, ensure `item` / `routeParams` binding matches existing `:param` names.

**Pages / flows to wire first (suggested — aligns with mobile Phase 7 migration):**

| Flow | Route(s) | `navigation_type` |
|------|----------|-------------------|
| List/grid → product detail | `/product/details/:productId` | `push` |
| Splash, carousel → next | `/splash-carousel`, `/auth/login`, … | `clear_stack` or omit |
| OTP verify → home | `/home` on `verifyOtp` `onSuccess` | omit or `clear_stack` |
| Settings logout | `/auth/login` on `logout` `onSuccess` | `clear_stack` (**in repo**) |
| Tab bar | tab routes | N/A — shell uses `go` in `TabShellWidget`, not `tap` |

---

### 2. Logout — `cubitCall` + navigate `onSuccess`

**Reference in prod JSON** (`settings-logout`):

```json
"tap": {
  "type": "cubitCall",
  "cubit": "auth",
  "method": "logout",
  "onSuccess": {
    "type": "navigate",
    "route": "/auth/login",
    "navigation_type": "clear_stack"
  }
}
```

Builder must support **`method: "logout"`** on auth `cubitCall` (clears token, then runs `onSuccess`). Do **not** use navigate-only logout without clearing session.

---

## Mobile engine reference (for builder team)

| Layer | File | Behavior |
|-------|------|----------|
| Parser / navigate | `lib/core/navigation/app_navigation.dart` | `parseNavigationType`, `AppNavigation.navigate` |
| Dispatch | `lib/engine/actions/action_dispatcher.dart` | `_handleNavigate` reads `navigation_type` |
| Schema notes | `lib/engine/validation/component_schemas.dart` | `navigateActionPropertyTypes` |
| AppBar back | `lib/engine/tree/renderers/app_bar_renderer.dart` | `context.canPop()` / `context.pop()` (works with `push`) |
| Auth toast | `lib/features/variantscreen/presentation/views/variant_screen.dart` | Success toast only on login — **no** duplicate `go` to `/home` |

No Dart changes required on builder side for this spec — informational.

---

## Example: before / after

**Before (navigate only — still valid, default clear stack):**

```json
"tap": {
  "type": "navigate",
  "route": "/product/details/:productId"
}
```

**After (product card — target for Phase 7):**

```json
"tap": {
  "type": "navigate",
  "route": "/product/details/:productId",
  "navigation_type": "push"
}
```

**Logout (implemented in repo):**

```json
"tap": {
  "type": "cubitCall",
  "cubit": "auth",
  "method": "logout",
  "onSuccess": {
    "type": "navigate",
    "route": "/auth/login",
    "navigation_type": "clear_stack"
  }
}
```

---

## Acceptance (builder done when)

- [ ] Builder UI can set `navigation_type` on navigate actions (dropdown: push / clear stack + aliases documented)
- [ ] Builder exports `logout` cubitCall + `onSuccess` navigate for settings
- [ ] Exported JSON includes `push` on agreed product-detail taps (Phase 7 rollout)
- [ ] Mobile app: detail back returns to list; logout stays on login without bounce to home

---

## Changelog

| Date | Author | Note |
|------|--------|------|
| 2026-05-22 | | Initial spec — engine Phases 1–4; partial prod JSON (logout only) |

---

## Related

- [NAVIGATION_IMPLEMENTATION_PHASES.md](../NAVIGATION_IMPLEMENTATION_PHASES.md) — Phase 7 JSON migration table
- [docs/ai/04-actions-and-requests.md](../../ai/04-actions-and-requests.md)
- [RULES.md](../../../RULES.md) §2.3 Navigation
