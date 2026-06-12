# Page padding — `pages[].padding`

> **Phase:** Layout / UI consistency  
> **Status:** `implemented-in-json`  
> **Active config:** `mobile_production_v2`  
> **Created:** 2026-06-11  

---

## Summary

Optional `pages[].padding` controls the default inset around page **body** content (below `appBar`). When omitted, the mobile engine applies `theme.spacing.md` (16px) on all sides. Set `0` for full-bleed splash/carousel screens. Body-level `style.padding` on individual blocks should not duplicate this outer inset.

---

## Gap vs production JSON

**Checked in** `assets/config/mobile_production_v2.json`:

| Item | Exists in prod JSON? | Evidence |
|------|----------------------|----------|
| `pages[].padding` | Yes (opt-out only) | `/splash`, `/splash-carousel` use `"padding": 0` |
| Default 16px via engine | Yes | All other pages rely on engine default + deduped body padding |

---

## Builder requirements

### 1. Page content inset

**Applies to:** `pages[]` entry (page-level field, not a component `type`)

**JSON shape (authoritative):**

```json
{
  "id": "page-checkout",
  "route": "/checkout",
  "title": "Checkout",
  "scroll": "vertical",
  "padding": 16,
  "body": []
}
```

| Field | Type | Required | Default (mobile) | Description |
|-------|------|----------|------------------|-------------|
| `padding` | number \| object \| `0` | no | `theme.spacing.md` (16) | Inset around body content below appBar |

**Value shapes:**

| Value | Behavior |
|-------|----------|
| Omitted | `theme.spacing.md` (typically 16) on all sides |
| `0` | No page inset — full-bleed body (splash, carousel) |
| `16` | Uniform 16px on all sides (explicit; same as default) |
| `{ "left": 16, "right": 16, "top": 12, "bottom": 8 }` | Per-side override |

Same parsing rules as component `padding` / `style.padding`.

**Engine behavior:**

| Step | Result |
|------|--------|
| `VariantRepository` | Resolves `pages[].padding`; injects `pagePadding` on synthetic root `column` |
| `ColumnRenderer` | Applies `pagePadding` to body region only — **not** on `appBar` |
| `layout: centered` | Padding applies inside padded body area; `expand` children fill remaining space |

**Validation rules for builder:**

- Do **not** duplicate outer horizontal padding on every section when page default applies — use `gap` / `margin` between sections instead.
- Full-bleed marketing/splash pages: `"padding": 0`.
- Card-inner padding, drawer items, and stack overlays are separate from page padding.

### 2. Three spacing roles (do not conflate)

| Spacing type | Owner | Example | Safe to remove when adding `pagePadding`? |
|--------------|-------|---------|------------------------------------------|
| Page outer inset | `pages[].padding` / engine `pagePadding` | 16px around body below appBar | N/A — engine default |
| Section vertical rhythm | parent `column.gap` or `padding.top` / `padding.bottom` (no left/right) | `home-browse-content` `gap: 12`; filter header `top: 12, bottom: 8` | **No** — still required |
| Card inner inset | `container.style.padding` on the card itself | hero `padding: 20`; profile greeting card `padding: 20` | **No** — still required |

**Dedupe rules when normalizing JSON:**

| Remove from body nodes | Keep on components |
|------------------------|-------------------|
| `left: 16` / `right: 16` on sections, grids, headers | `padding: 20` inside hero/profile cards |
| `padding: 16` on page root wrappers (`checkout-steps-wrap`, `settings-list`) | `gap: 8–12` on menu/list columns |
| Uniform `padding: 16` used only as page gutter | Small inner paddings (8–14) on card rows and grid item bodies |

Removing card inner padding or section vertical spacing while deduping page gutter causes text flush to card edges and collapsed sections.

**Pages wired in production (reference):**

| Route | `padding` | Notes |
|-------|-----------|-------|
| `/splash` | `0` | Full-bleed centered layout |
| `/splash-carousel` | `0` | Full-bleed carousel |
| All other pages | _(omit)_ | Engine default 16px |

---

## Mobile implementation

| File | Role |
|------|------|
| `lib/features/variantscreen/data/repos/variant_repository.dart` | Resolve `pages[].padding` → `pagePadding` on root column |
| `lib/engine/tree/renderers/column_renderer.dart` | Render `pagePadding` on body-only region |

---

## Related

- [15-page-layout-preset.md](15-page-layout-preset.md) — `pages[].layout: "centered"`
- [08-page-scroll.md](08-page-scroll.md) — `pages[].scroll`
- [19-sized-box-spacing.md](19-sized-box-spacing.md) — internal spacing between siblings
