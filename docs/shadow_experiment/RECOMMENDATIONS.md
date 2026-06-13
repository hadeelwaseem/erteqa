# Shadow / elevation recommendations (architecture)

**Status:** Reference — strong production tier shipped. See [`../shadow_audit_summary.md`](../shadow_audit_summary.md).

---

## What the screenshots show

### Clear wins (pipeline + direction)

| Surface | Mechanism | Observation |
|---------|-----------|-------------|
| **Cart checkout panel** | `card` + `elevation: 8` + transparent `surfaceTintColor` | Strong, obvious float — best full-screen result |
| **Home hero** | `container` + `shadow: xl` on dark `#0F172A` | Visible under-edge glow on light page |
| **Composite golden** | `md` / `xl` BoxShadow + card `elevation: 6–8` | All presets clearly separated on `#F1F5F9` |

### Still too subtle on device (even with experiment values)

| Surface | Config | Why it stays flat-ish |
|---------|--------|------------------------|
| **Product grid cards** | `card` + `elevation: 6` | White-on-`#F1F5F9`, tight grid spacing, Material shadow mostly below fold of adjacent cells |
| **Product info block** | `elevation: 8` | Same palette; less free margin than checkout dock |
| **Account / login cards** | `elevation: 6` | Identical issue — elevation reads as hairline on white tiles |
| **Search field** | `textFormField` + `shadow: md` | Light field `#F8FAFC` on grey page; border dominates |
| **Search screen (idle)** | No autocomplete visible | Panel has zero height when empty — nothing to shadow |

### Experiment “too strong” reference

The composite golden at `test/engine/goldens/experiment_strong_shadow_composite.png` is the upper bound. **Cart checkout at elevation 8** is acceptable strong; **xl on every white card** would feel heavy in production.

---

## Recommended production token scale

Dial back ~35–45% from experiment values. Target: obvious at 100% zoom on `#F1F5F9`, not “double stacked”.

| Preset | Production target | Role |
|--------|-------------------|------|
| **sm** | `color: 0x24000000`, blur **6**, offset **(0, 2)** | Inset chips, subtle field hint — still visible on grey |
| **md** | `color: 0x38000000`, blur **12**, spread **0.5**, offset **(0, 4)** | Search fields, filter bars, dropdown triggers |
| **lg** | `color: 0x47000000`, blur **18**, spread **1**, offset **(0, 6)** | Product tiles, account rows, hero on light surfaces |
| **xl** | `color: 0x52000000`, blur **24**, spread **1.5**, offset **(0, 9)** | Autocomplete, checkout dock, sheets, dialogs |

**Experiment values (do not ship):** sm 0x33/8px, md 0x47/16px, lg 0x59/24px, xl 0x66/32px.

Validate with an updated `diagnostic_boxshadow_ladder.png` — **`md` must be clearly visible** without squinting.

---

## BoxShadow vs Material elevation vs flat

### Prefer **BoxShadow** (`container` / `textFormField` `shadow` preset)

Controlled, consistent on light backgrounds; use when the surface must “float” over `#F1F5F9`:

| Component | Preset | Notes |
|-----------|--------|-------|
| Autocomplete panels (`home-search-autocomplete-panel`, `search-autocomplete-panel`) | **xl** (prod) | Only when visible; keep `visibleWhen` |
| Search / OTP inputs (`home-search-field`, `search-field`, login fields) | **md** | Stronger than border-only |
| Hero promo (`home-hero-section`) | **lg** on dark bg (xl optional) | Dark card already contrasts; lg is enough |
| Checkout dock | **xl** *or* card elevation — pick one, not both | Cart experiment: elevation 8 worked well |
| Bottom sheets, modal overlays, engine dropdowns | **xl** | When those surfaces exist in JSON |
| `AppMessenger` toasts | **lg** | Match overlay tier |

### Prefer **Material elevation** (`card` + `elevation` + renderer policy)

Use for card-shaped content blocks where M3 shadow is acceptable **after** `surfaceTintColor: Colors.transparent` and explicit `shadowColor`:

| Component | Production elevation | Notes |
|-----------|---------------------|-------|
| Product grid / list items | **3–4** | Experiment `6` is heavy in dense grids; add **8px grid gap** if shadows should breathe |
| Product info block | **4–6** | Experiment `8` is max for this pattern |
| Cart checkout panel | **6–8** | Keep sticky dock feel (experiment validated) |
| Account menu rows / welcome card | **2–3** | Gentle lift; avoid matching product tiles |
| Expansion tiles (description) | **1–2** or flat | Inline content, not floating |

**Renderer policy (keep for PR2):**

```dart
Card(
  surfaceTintColor: Colors.transparent,
  shadowColor: const Color(0x47000000), // match ~lg token, not experiment 0x59
  ...
)
```

Document in builder spec: **M3 `elevation: 1–2` ≠ `md` BoxShadow** on this background.

### **Remain flat** (`elevation: 0`, no shadow)

| Surface | Reason |
|---------|--------|
| App bars | Standard flat chrome; already `elevation: 0` in prod |
| Bottom navigation | Divider / hairline only |
| Page / scaffold background | No shadow on scroll canvas |
| Primary buttons (`button`) | Filled CTA — flat is correct for M3 |
| Category circles on home (grey placeholders) | Optional **sm** only if tiles need affordance; default flat |
| Thumbnails / image placeholders | Border for selection state, not elevation |
| Dividers, inline text, icons | N/A |

---

## JSON hierarchy (PR2 scope)

After rebaseline tokens:

1. **Overlays:** autocomplete → `shadow: lg` or `xl`; checkout → `elevation: 6` or container `xl`
2. **Inputs:** home/search fields → `shadow: md` (already in experiment JSON)
3. **Cards:** product grids → `elevation: 3` or `4` (not 6); info block → `4`–`6`
4. **Spacing:** increase grid `gap` / card `margin` where shadows are clipped by neighbors
5. **Theme defaults (PR2):** `MobileThemeConfig.defaultShadows` for opt-in fallbacks — document in `builder-specs/26-default-shadows.md`

---

## Acceptance criteria (production)

On `#F1F5F9` at 100% zoom:

1. Side-by-side before/after: **checkout, autocomplete, and search field** show obvious depth change
2. Product card shadow visible **without** overlapping neighbor clipping
3. Account/login screens stay **calmer** than cart/checkout (lower tier)
4. No surface uses experiment xl on every white card

---

## Revert checklist (when leaving experiment branch)

1. Restore `shadow_tokens.dart` to production table above (not pre-Pass-A weak values)
2. Revert or re-run JSON patch inverse (card elevations, shadow presets)
3. Keep `card_renderer` tint/shadowColor policy if adopted for PR2
4. Regenerate diagnostic goldens on production tokens

---

## Summary decision

| Question | Answer |
|----------|--------|
| Final token scale? | **sm/md/lg/xl table above** (~40% softer than experiment) |
| BoxShadow for? | **Overlays, inputs, toasts, hero (optional)** |
| Material elevation for? | **Product/account cards, checkout** with transparent tint + explicit shadowColor |
| Flat? | **Chrome, buttons, page bg, optional category tiles** |

Proceed to PR2 on a new branch from main with production tokens + selective JSON, not the full experiment bump.

**Update (audit closed):** Production tokens are in `shadow_tokens.dart`; Pass A JSON is in `mobile_production_v2.json`. No further shadow PRs planned.
