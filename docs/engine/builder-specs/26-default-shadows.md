# Builder spec: Theme defaultShadows (component shadow presets)

> **Phase:** Shadow cleanup P2  
> **Status:** `ready-for-builder`  
> **Active config:** `mobile_production_v2`  
> **Created:** 2026-06-12  

---

## Summary

Mobile engine supports optional **theme-level default shadow presets** per component type. When a node omits `elevation` (card, appBar) or `shadow` (container, textFormField), the engine falls back to `theme.defaultShadows.{type}` before hardcoded renderer defaults.

Presets only: `none` | `sm` | `md` | `lg` | `xl`. Material surfaces use Material elevation; containers and fields use BoxShadow presets.

---

## Gap vs production JSON

**Checked in** `assets/config/mobile_production_v2.json`:

| Item | Exists in prod JSON? | Evidence |
|------|----------------------|----------|
| `theme.defaultShadows` | No | Prod uses per-node `elevation: 0` on cards/app bars and one `style.shadow: "lg"` hero |
| `props.shadow` on `container` | Yes | Home hero — `"shadow": "lg"` |
| `props.elevation` on `appBar` | Yes | All 21 app bars — `"elevation": 0` |

Absent `defaultShadows` → **no behavior change** (renderer hardcoded defaults apply).

---

## Builder requirements

### 1. Theme defaultShadows

**Applies to:** top-level `theme` object

```json
{
  "theme": {
    "defaultShadows": {
      "card": "none",
      "appBar": "sm",
      "container": "none",
      "textFormField": "none"
    }
  }
}
```

| Key | Type | Required | Allowed values | Description |
|-----|------|----------|----------------|-------------|
| `card` | string | no | `none`, `sm`, `md`, `lg`, `xl` | Default when `card.props.elevation` omitted |
| `appBar` | string | no | same | Default when `appBar.props.elevation` omitted |
| `container` | string | no | same | Default when `container` `shadow` / `style.shadow` omitted |
| `textFormField` | string | no | same | Default when `textFormField.props.shadow` omitted |

**Precedence:** explicit node prop → `theme.defaultShadows.{type}` → renderer hardcoded default.

**Material mapping** (card, appBar): `none→0`, `sm→1`, `md→2`, `lg→4`, `xl→8`.

**BoxShadow mapping** (container, textFormField): preset tokens in `lib/engine/theme/shadow_tokens.dart` (production values as of shadow audit closure).

---

## Engine reference

| Module | Path |
|--------|------|
| Tokens | `lib/engine/theme/shadow_tokens.dart` |
| Parser | `lib/engine/theme/shadow_parser.dart` |
| Theme model | `lib/config/models/mobile_theme_config.dart` |
| Theme bridge | `lib/engine/theme/engine_theme.dart` |

---

## Out of scope

- Per-level blur/opacity customization
- Global `shadows.enabled` kill switch
- Custom shadow objects `{ blur, offsetY, … }`
- `shadow` string alias on `card` (use `elevation` or theme default)

---

## Checklist

- [x] Engine parses `theme.defaultShadows`
- [x] Renderers honor fallback chain
- [ ] Builder UI exposes optional `defaultShadows` map
- [ ] Prod JSON may add block when merchant needs global defaults without per-node props
