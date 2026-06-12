# Builder spec: Conditional visibility (`visibleWhen`)

> **Phase:** Home inline search / engine orchestration  
> **Status:** `implemented-in-json`  
> **Active config:** `mobile_production_v2`  
> **Created:** 2026-06-11  

---

## Summary

The mobile engine supports optional `props.visibleWhen` on any component node. When the condition fails, the node renders as zero height (`SizedBox.shrink`). Used on `/home` to hide browse sections while the inline search field has text.

---

## Gap vs production JSON

| Item | Exists in prod JSON? | Evidence |
|------|----------------------|----------|
| `props.visibleWhen` | Yes | `/home` `home-browse-content`, `home-search-results-header` |

---

## Builder requirements

### 1. `visibleWhen`

**Applies to:** any component `type` (wired in `ScreenRenderer`).

**JSON shape:**

```json
{
  "type": "column",
  "props": {
    "visibleWhen": {
      "source": "form",
      "field": "homeSearchQuery",
      "when": "isEmpty"
    }
  }
}
```

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `source` | string | no | `form` | `form` or `pageState` |
| `field` | string | yes | — | Form field id or pageState key |
| `when` | string | no | `nonEmpty` | `isEmpty` or `nonEmpty` |

**Pages wired in repo:**

| Route | Node id | Condition |
|-------|---------|-----------|
| `/home` | `home-browse-content` | `isEmpty` on `homeSearchQuery` |
| `/home` | `home-search-results-header` | `nonEmpty` on `homeSearchQuery` |

---

## Mobile engine reference

| Layer | File | Behavior |
|-------|------|----------|
| Visibility | `lib/engine/visibility/visible_when.dart` | Parses spec; `form` uses `ListenableBuilder` on field controller |
| Renderer | `lib/engine/screen_renderer/screen_renderer.dart` | Wraps rendered widget when `visibleWhen` present |

---

## Changelog

| Date | Author | Note |
|------|--------|------|
| 2026-06-11 | | Initial spec for home inline search |
