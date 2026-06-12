# Builder spec: textFormField textDirection and clearable

> **Phase:** UI fixes — phone / numeric input  
> **Status:** `implemented-in-json`  
> **Active config:** `mobile_production_v2`  
> **Created:** 2026-05-23  

---

## Summary

`textFormField` supports optional `textDirection` (`ltr` | `rtl`). When omitted and `keyboardType` is `phone`, the engine defaults to **LTR** so international numbers display as `+963…` in RTL apps.

---

## Gap vs production JSON

| Item | Exists in prod JSON? | Evidence |
|------|----------------------|----------|
| `props.textDirection` on `textFormField` | Yes | `auth-login-phone`, `address-field-phone` |
| `props.clearable` / `clearIcon` | Yes | `home-search-field` |

---

## Builder requirements

### textFormField.textDirection

**Applies to:** `type` = `textFormField`

**JSON shape:**

```json
{
  "type": "textFormField",
  "props": {
    "id": "phone",
    "keyboardType": "phone",
    "textDirection": "ltr",
    "textAlign": "left"
  }
}
```

**Rules:**

- Use `ltr` + `left` for phone and E.164-style fields.
- Omit or use `rtl` + `right` for Arabic name/address copy.

### textFormField.clearable

**JSON shape:**

```json
{
  "type": "textFormField",
  "props": {
    "id": "homeSearchQuery",
    "prefixIcon": "search",
    "clearable": true,
    "clearIcon": "close"
  }
}
```

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `clearable` | bool | false | Shows a tappable suffix icon when the field has text; clears input on tap |
| `clearIcon` | string | `close` | Icon name (`close`, `clear`, `delete`, …) |

In RTL layouts the clear icon appears on the visual left (suffix), opposite `prefixIcon`.

---

## Mobile engine reference

- [`lib/engine/tree/renderers/text_form_field_renderer.dart`](../../../lib/engine/tree/renderers/text_form_field_renderer.dart)
- [`lib/engine/validation/component_schemas.dart`](../../../lib/engine/validation/component_schemas.dart) — `textFormField` optional `textDirection`
