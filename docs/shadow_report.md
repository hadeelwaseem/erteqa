# Shadow / Elevation System Audit (initial inventory)

> **Superseded (2026-06-12).** This document captured the **pre-fix inventory**. For closure status, shipped values, and strategy, use **[`shadow_audit_summary.md`](shadow_audit_summary.md)**. Root-cause analysis: **[`shadow_diagnostic_report.md`](shadow_diagnostic_report.md)**. Architecture reference: **[`shadow_experiment/RECOMMENDATIONS.md`](shadow_experiment/RECOMMENDATIONS.md)**.

This audit follows the JSON-first, layer-separated architecture in [AGENTS.md](AGENTS.md). The app is a **dynamic UI generator** — merchant-visible depth should ultimately be **theme- and JSON-driven**, not scattered hardcoded values in Dart.

---

## Executive summary (historical — see links above)

The codebase has **two parallel shadow systems** that are not unified:

| System | Mechanism | JSON control | Used by |
|--------|-----------|--------------|---------|
| **Material elevation** | Flutter `Material.elevation` / `Card.elevation` | `elevation` (number) | `card`, `appBar` |
| **BoxShadow presets** | Hardcoded `sm` / `md` / `lg` / `xl` → `BoxShadow` | `shadow` (string) | `container`, `textFormField` |

There is **no shadow block in `theme`**, **no shared token module**, and **duplicated preset logic** in two renderers. Production config (`mobile_production_v2.json`) deliberately uses a **flat aesthetic**: all **32 cards** set `"elevation": 0`, only **one container** uses `"shadow": "lg"`, and only **2 of 21 app bars** set `"elevation": 0` — the rest inherit the renderer default of **1**, creating an inconsistent chrome-vs-content hierarchy.

---

## 1. Complete inventory of current shadow usage

### 1.1 Engine renderers (JSON-driven)

| File | Prop(s) | Implementation | Defaults | JSON in prod v2 |
|------|---------|----------------|----------|-----------------|
| `lib/engine/tree/renderers/container_renderer.dart` | `shadow` (`props` or `style.shadow` via repo merge) | `BoxDecoration.boxShadow` via `_parseShadow()` | `null` (none) | **1×** `"shadow": "lg"` (home hero) |
| `lib/engine/tree/renderers/text_form_field_renderer.dart` | `shadow` | `DecoratedBox` wrapper around field | `null` (none) | **0** |
| `lib/engine/tree/renderers/card_renderer.dart` | `elevation`, `borderRadius`, `color`, `margin` | Flutter `Card(elevation: …)` | `elevation: 0.0` | **32×** `"elevation": 0` |
| `lib/engine/tree/renderers/app_bar_renderer.dart` | `elevation` | `Material(elevation: …)` | `elevation: 1.0` | **2×** `"elevation": 0` (product details, cart) |
| `lib/engine/tree/renderers/button_renderer.dart` | — | `FilledButton` / `OutlinedButton` / `TextButton` (M3 implicit) | Platform M3 | **0** |
| `lib/engine/tree/renderers/contact_button_renderer.dart` | — | `FilledButton` (M3 implicit) | Platform M3 | **0** |

**Hardcoded preset values** (identical in `container_renderer.dart` L236–265 and `text_form_field_renderer.dart` L519–548):

| Preset | Color | blurRadius | offset |
|--------|-------|------------|--------|
| `sm` | `0x1A000000` (10% black) | 4 | `(0, 1)` |
| `md` | `0x26000000` (15%) | 8 | `(0, 2)` |
| `lg` | `0x33000000` (20%) | 16 | `(0, 4)` |
| `xl` | `0x40000000` (25%) | 24 | `(0, 8)` |
| `none` / omitted | — | — | — |

### 1.2 Config / theme layer

| File | Shadow support |
|------|----------------|
| `lib/config/models/mobile_theme_config.dart` | **None** — has `colors`, `radius`, `spacing`, `buttons` only |
| `lib/engine/theme/engine_theme.dart` | **None** — no shadow helpers; `toThemeData()` sets `ColorScheme` + typography only (no `CardTheme`, `AppBarTheme`, `elevation` overrides) |
| `assets/config/mobile_production_v2.json` `theme` block | **None** |

### 1.3 JSON ingestion path

`variant_repository.dart` merges builder `style.shadow` → `properties['shadow']` for containers (L339–340). There is **no equivalent** `style.elevation` merge for cards.

### 1.4 Schema documentation

`lib/engine/validation/component_schemas.dart`:

- `container.shadow`: `string (sm|md|lg|xl|none)` ✅ matches implementation
- `textFormField.shadow`: `string` ✅ (loosely typed)
- `card.elevation`: `number` ✅; `card.shadowColor`: documented ❌ **not implemented** in `card_renderer.dart`
- `appBar.elevation`: `number` ✅
- `button`, `contactButton`, `dropdown`, `expansionTile`, etc.: **no shadow/elevation keys**

### 1.5 Shell / chrome (not JSON-configurable)

| Location | Shadow behavior |
|----------|-----------------|
| `lib/features/shell/presentation/views/tab_shell_widget.dart` | `BottomNavigationBar` — Material default elevation (~8 dp) |
| `lib/engine/tree/renderers/app_drawer_renderer.dart` | `Drawer` — Flutter default elevation (16 dp) |
| `lib/engine/tree/renderers/image_slider_renderer.dart` | `showDialog` fullscreen preview — Material dialog default elevation |
| `lib/features/commerce/checkout/.../checkout_location_picker_page.dart` | `FloatingActionButton` — Material default |

### 1.6 Core feedback (intentionally outside JSON)

| Location | Values |
|----------|--------|
| `lib/core/feedback/app_messenger.dart` L327–332 | `BoxShadow(color: black 12%, blurRadius: 12, offset: (0, 4))` — close to `lg` preset but separate |

### 1.7 Legacy / dev-only hardcoded widgets (outside engine)

| File | Values | Risk |
|------|--------|------|
| `lib/features/homescreen/presentation/views/home_screen.dart` L94–99 | `blurRadius: 12`, `offset: (0, 6)`, `alpha: 0.05` | Dev route `/mvp2`; violates JSON-first for merchant UI |
| `lib/features/auth/presentation/views/widgets/option_card.dart` L23 | `Card(elevation: 10)` | Legacy auth widget; extreme vs prod flat cards |

### 1.8 Documentation / web-builder contract (not runtime)

| Doc | Content |
|-----|---------|
| `docs/blocks.md` §4.5 | Rich web model: `shadowMode`, `shadowPreset`, custom offset/blur/spread/color |
| `docs/engine/web-to-mobile-converter/06-layout-cross-cutting.md` | Maps web presets → mobile `shadow` or `card.elevation`; custom shadows → approximate `elevation: 2` |
| `docs/engine/JSON_SOURCE_OF_TRUTH_AUDIT.md` | Flags container shadow palette as **P1 hardcoded** |
| `docs/engine/builder-specs/17-appbar-layout-ui.md` | Documents `appBar.elevation` (implemented) |

### 1.9 Test coverage

| Tests | Coverage |
|-------|----------|
| `test/engine/renderers/app_bar_renderer_test.dart` | Elevation default `1`, transparent at `0` |
| **No tests** for container/textFormField shadow presets, card elevation, or theme integration |

---

## 2. Component coverage matrix

Legend: ✅ full · 🟡 partial · ❌ none · ➖ not applicable · 🔧 should have

| Component | Current | JSON today | Should support? | Gap |
|-----------|---------|------------|-----------------|-----|
| **container** | ✅ `shadow` presets | `props.shadow` / `style.shadow` | ✅ | Tokens hardcoded; not theme-aware |
| **textFormField** | ✅ `shadow` presets | `props.shadow` | 🟡 optional | Same duplication; rare in prod |
| **card** | 🟡 `elevation` only | `props.elevation` | ✅ | No `shadow` alias; `shadowColor` unimplemented; can't use presets |
| **appBar** | ✅ `elevation` | `props.elevation` | ✅ | Default `1` conflicts with prod flat cards; 19/21 bars get implicit shadow |
| **button** | ❌ M3 implicit | — | 🟡 elevated variant only | No `shadow` / `elevation` prop |
| **contactButton** | ❌ M3 implicit | — | 🟡 | Same as button |
| **dropdown** | ❌ | — | 🟡 | Menu overlay uses Material defaults |
| **expansionTile** | ❌ flat Material | — | ➖ | Border/divider sufficient |
| **tabs** | ❌ underline only | — | ➖ | |
| **otpInput** | ❌ border focus | — | ➖ | |
| **imageSlider** | ❌ border on thumbs | — | ➖ | |
| **listView / gridView** | ➖ via items | — | ➖ | Depth from child cards/containers |
| **scaffold** | ❌ `ColoredBox` only | — | ➖ | |
| **appDrawer** | 🔧 Flutter default | `width`, `backgroundColor` | 🟡 | No elevation override |
| **divider, text, icon, image, …** | ❌ | — | ➖ | |
| **chips** | ❌ type doesn't exist | — | N/A until type added | |
| **bottom nav** | 🔧 Material default | — | 🟡 | Shell chrome; theme-level |
| **FAB** | 🔧 Material default | — | ➖ | Feature widget, not JSON |
| **dialogs / modals** | 🔧 Material default | — | ➖ | Engine-owned (`image_slider`) |
| **banners / hero** | ✅ via `container` | `style.shadow` | ✅ | Only prod usage of shadow |
| **product cards** | ✅ via `card` | `elevation: 0` everywhere | ✅ | Flat by design; borders could substitute |
| **list items** | ✅ via nested `card` | same | ✅ | |
| **AppMessenger toasts** | 🔧 hardcoded | — | 🟡 | Should use shared tokens |

---

## 3. Design quality assessment

### Strengths

- Production v2 commits to a **coherent flat-card pattern**: white `#FFFFFF` surfaces on `#F1F5F9` background, `borderRadius: 10`, `elevation: 0` — aligns with modern mobile flat UI.
- `container.shadow` presets are **simple for merchants** and match web builder vocabulary (`sm`–`xl`).
- `appBar` supports **flat overlay bars** (`elevation: 0` + transparent `backgroundColor`) — documented in builder-spec 17.

### Weaknesses

| Issue | Impact |
|-------|--------|
| **Dual APIs** (`elevation` vs `shadow`) | Merchants/builders must know which type accepts which prop; web converter maps inconsistently |
| **Duplicated `_parseShadow`** | Drift risk; already identical but unmaintained as one source |
| **No theme tokens** | Merchants cannot brand shadow color/intensity globally |
| **Fixed black rgba** | Poor dark-mode readiness; shadows invisible on dark surfaces |
| **App bar default `elevation: 1`** vs flat cards | Visual hierarchy inverted on 19 pages — chrome casts shadow while content is flat |
| **Schema drift** | `card.shadowColor` documented, not rendered |
| **`Card` M3 surface tint** | Not disabled (unlike app bar's `surfaceTintColor: transparent`); can cause subtle color shift |
| **No tests** for shadow presets | Regressions likely during centralization |
| **Performance** | `BoxShadow` on many nodes triggers extra compositing; prod minimizes this (1 shadow node); scaling shadow to all cards would cost GPU layers |
| **Accessibility** | Shadows are decorative only — OK; but low-contrast flat cards rely entirely on background contrast (acceptable given prod palette) |

### Platform considerations

- **Material elevation** uses platform shadow rendering (different on Android vs iOS).
- **BoxShadow presets** look identical cross-platform but don't respond to system "reduce transparency" settings.
- **M3** is enabled (`useMaterial3: true` in `main.dart`); `FilledButton` is largely flat — `variant: elevated` is a misnomer today.

---

## 4. Proposed shadow design system architecture

### 4.1 Layer model

```
assets/config/*.json
  theme.shadows.{sm,md,lg,xl}     ← merchant global defaults (optional)
  theme.shadows.enabled: false    ← global kill switch (optional)
  component.props.shadow          ← per-node override (unified string)
  component.props.elevation       ← legacy alias / Material-native (card, appBar)

lib/config/models/mobile_theme_config.dart
  ThemeShadows model

lib/engine/theme/shadow_tokens.dart          ← NEW: canonical preset → BoxShadow
lib/engine/theme/elevation_tokens.dart       ← NEW: preset → Material elevation map
lib/engine/theme/engine_theme.dart           ← shadowFor(preset), defaultFor(type)

lib/engine/tree/parsers/shadow_parser.dart   ← NEW: single parser used by all renderers
```

### 4.2 Token set (recommended defaults)

| Token | BoxShadow | Material elevation equivalent | Typical use |
|-------|-----------|-------------------------------|-------------|
| `none` | — | `0` | Cards, list tiles (prod default) |
| `sm` | blur 4, y 1, α 10% | `1` | App bars, sticky subheaders |
| `md` | blur 8, y 2, α 15% | `2` | Raised buttons, input focus |
| `lg` | blur 16, y 4, α 20% | `4` | Hero banners, floating panels |
| `xl` | blur 24, y 8, α 25% | `8` | Modals, FAB, drawers |

Keep **existing numeric values** initially for backward compatibility; allow theme override of `color`, `blurRadius`, `offsetY` per level later.

### 4.3 Unified JSON contract

**Primary prop (all surface components):**

```json
"shadow": "none" | "sm" | "md" | "lg" | "xl"
```

**Legacy / Material-specific (retain):**

```json
"elevation": 0
```

**Resolution order:**

1. Component `props.shadow` (or `style.shadow` for builder nodes)
2. Component `props.elevation` → map through `elevation_tokens` (optional bridge)
3. `theme.shadows.defaults.{card|appBar|container|button}` 
4. Engine hardcoded fallback (current values)

**Global disable:**

```json
"theme": {
  "shadows": {
    "enabled": false
  }
}
```

Resolves all shadows to `none` unless a component explicitly sets `shadow: "lg"` (merchant opt-in override) — exact precedence should be documented in builder-spec.

### 4.4 Renderer strategy

| Renderer | Recommended approach |
|----------|---------------------|
| `card` | Accept `shadow` preset **or** `elevation`; implement via `Material` + `elevation` **or** `PhysicalModel`/`DecoratedBox` for consistent BoxShadow look; wire `shadowColor` from theme |
| `container` | Replace local `_parseShadow` with shared parser + theme |
| `textFormField` | Same shared parser |
| `appBar` | Default from `theme.shadows.defaults.appBar` (suggest `sm` or `none` to match prod); keep `elevation` for fine control |
| `button` | Add optional `shadow` for `elevated`/`filled` variants only |
| `dropdown` | Optional `menuElevation` later — lower priority |

### 4.5 Merchant customization matrix

| Need | Mechanism |
|------|-----------|
| Use defaults automatically | `theme.shadows.defaults.*` + component-type fallbacks |
| Override per component | `props.shadow: "lg"` |
| Disable all shadows | `theme.shadows.enabled: false` |
| Disable one component | `props.shadow: "none"` or `elevation: 0` |
| Custom brand shadow color | Phase 2: `theme.shadows.color` or per-level `theme.shadows.lg.color` |
| Full custom (web parity) | Phase 3: `shadow: { blur, offsetY, spread, color }` object |

---

## 5. Recommended JSON schema updates

### 5.1 Theme block (new — requires builder-spec)

```json
"theme": {
  "shadows": {
    "enabled": true,
    "color": "#000000",
    "defaults": {
      "card": "none",
      "appBar": "sm",
      "container": "none",
      "button": "none",
      "textFormField": "none"
    },
    "levels": {
      "sm": { "blur": 4, "offsetY": 1, "opacity": 0.10 },
      "md": { "blur": 8, "offsetY": 2, "opacity": 0.15 },
      "lg": { "blur": 16, "offsetY": 4, "opacity": 0.20 },
      "xl": { "blur": 24, "offsetY": 8, "opacity": 0.25 }
    }
  }
}
```

### 5.2 Component prop extensions

| Type | Add / clarify |
|------|---------------|
| `card` | `shadow` (string preset); implement `shadowColor`; deprecate raw `elevation` in docs (keep supported) |
| `button`, `contactButton` | `shadow` (optional) |
| `appBar` | `shadow` alias for `elevation` mapping |
| `dropdown` | `menuElevation` (future) |
| `container`, `textFormField` | Document theme fallback; optional `shadowColor` |

**Builder-spec required** before implementation: `docs/engine/builder-specs/18-shadow-elevation-system.md` (new), index update in `builder-specs/README.md`.

---

## 6. Prioritized implementation plan

| Priority | Item | Complexity | Files | Rationale |
|----------|------|------------|-------|-----------|
| **P0** | Extract `ShadowParser` / `ShadowTokens` from duplicated code | **S** (1–2 days) | `shadow_parser.dart`, `shadow_tokens.dart`, `container_renderer.dart`, `text_form_field_renderer.dart` | Eliminates drift; zero visual change |
| **P0** | Unit tests for all presets + `none` + unknown | **S** | `test/engine/theme/shadow_parser_test.dart` | Safety net |
| **P1** | Add `ThemeShadows` to `MobileThemeConfig` + `EngineTheme.shadowFor()` | **M** (2–3 days) | `mobile_theme_config.dart`, `engine_theme.dart`, builder-spec | Enables merchant branding |
| **P1** | Unify `card` API: add `shadow` preset; implement `shadowColor`; disable M3 surface tint | **M** | `card_renderer.dart`, `component_schemas.dart` | 32 prod cards; schema already promises `shadowColor` |
| **P1** | Align `appBar` default with prod (`none` or theme `sm`); set explicit `elevation: 0` on remaining 19 app bars **or** change default | **S–M** | `app_bar_renderer.dart`, prod JSON | Fixes chrome/content inconsistency |
| **P2** | `button` / `contactButton` optional `shadow` | **S** | `button_renderer.dart`, `contact_button_renderer.dart` | Completes CTA depth control |
| **P2** | `AppMessenger` + shell chrome use tokens | **S** | `app_messenger.dart`, `tab_shell_widget.dart` | Visual consistency |
| **P2** | `style.elevation` merge in `variant_repository` | **S** | `variant_repository.dart` | Builder parity with `style.shadow` |
| **P3** | Custom shadow object (web `shadowMode: custom`) | **L** | parser, schemas, converter docs | Web parity |
| **P3** | `dropdown` menu elevation, `appDrawer` elevation props | **M** | respective renderers | Shell polish |
| **P3** | Dark mode shadow color adaptation | **M** | `EngineTheme`, theme JSON | Future `theme.mode: dark` |
| **Defer** | New `chip` component | **L** | new type + renderer | Type doesn't exist |

---

## 7. Specific files to modify (implementation phase)

| Layer | Files |
|-------|-------|
| **Config models** | `lib/config/models/mobile_theme_config.dart` |
| **Theme bridge** | `lib/engine/theme/engine_theme.dart`, new `shadow_tokens.dart`, `shadow_parser.dart` |
| **Renderers** | `container_renderer.dart`, `text_form_field_renderer.dart`, `card_renderer.dart`, `app_bar_renderer.dart`, `button_renderer.dart`, `contact_button_renderer.dart` |
| **Validation** | `lib/engine/validation/component_schemas.dart` |
| **JSON ingestion** | `lib/features/variantscreen/data/repos/variant_repository.dart` |
| **Core chrome** | `lib/core/feedback/app_messenger.dart`, `lib/features/shell/presentation/views/tab_shell_widget.dart` |
| **Tests** | `test/engine/theme/`, `test/engine/renderers/card_renderer_test.dart`, extend `app_bar_renderer_test.dart` |
| **Docs** | `docs/engine/builder-specs/18-shadow-elevation-system.md`, `docs/engine/web-to-mobile-converter/06-layout-cross-cutting.md` |
| **Prod JSON** (when allowed) | `assets/config/mobile_production_v2.json` — add `theme.shadows` + normalize app bar elevations |

---

## 8. Risks, edge cases, backward compatibility

| Risk | Mitigation |
|------|------------|
| Changing `appBar` default `elevation` from `1` → `0` | Visually significant on 19 pages — either change default **or** add explicit JSON; prefer theme default + prod JSON explicit values |
| `card` supporting both `shadow` and `elevation` | Define precedence: `shadow` wins; never apply both BoxShadow and Material elevation |
| `elevation: 1` on old configs vs new preset mapping | Keep numeric `elevation` as escape hatch; document mapping table |
| Theme `shadows.enabled: false` vs per-node `shadow: "lg"` | Document: global disable wins **unless** `shadow` is explicitly non-`none` (merchant choice) |
| `style.shadow` only merged for builder nodes | Extend merge for `elevation` and document which types honor `style.*` |
| BoxShadow performance at scale | Default `card` to `none` (current prod); warn in builder-spec against `lg` on every grid item |
| iOS vs Android elevation differences | For pixel-perfect parity, prefer BoxShadow path for cards; keep Material elevation for app bars |
| `shadowColor` on card (schema exists) | Implement when centralizing; default to `theme.shadows.color` |
| Legacy widgets (`option_card`, `home_screen`) | Out of scope for engine; mark deprecated or migrate to JSON routes |
| Builder tool lag | Ship builder-spec **before** Dart changes per project rules |
| M3 `Card` surface tint | Set `surfaceTintColor: Colors.transparent` when using flat cards (matches app bar pattern) |

---

## 9. Gap analysis summary

| Category | Status |
|----------|--------|
| **Existing implementations** | 4 engine touchpoints (`container`, `textFormField`, `card`, `appBar`) + shell Material defaults + `AppMessenger` |
| **Missing capabilities** | Theme-level shadows, unified API, `card.shadow` / `shadowColor`, button shadow, global disable, custom shadows, tests |
| **Inconsistent implementations** | Dual `elevation` vs `shadow`; duplicated parsers; app bar defaults vs flat prod cards; web builder richer than mobile |
| **Components needing enhancement** | `card` (highest), `appBar` (default), `button`, shell chrome, `AppMessenger` |
| **Production reality** | Intentionally flat — shadows are **infrastructure-ready but barely used** (1 hero container); work is about **consistency and merchant control**, not adding shadows everywhere |

---

## Recommended next step

When you are ready to implement, start with **P0 only** (shared `ShadowParser` + tests, no visual changes), then add the **builder-spec** for `theme.shadows` before touching `MobileThemeConfig` or prod JSON. That sequence respects the project's builder-spec rule and minimizes regression risk on the current flat production aesthetic.

I have not made any code changes per your request. Say if you want Phase 1 (P0 centralization) or the full builder-spec drafted next.