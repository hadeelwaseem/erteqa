# Shadow / elevation audit — complete

**Status:** Closed — **strong production tier** applied (2026-06-12)  
**Rationale:** Conservative tokens (`elevation: 1–2`, `shadow: md`) were still invisible on `#F1F5F9`. Production now uses the experiment-validated strong scale for Pass A surfaces only; chrome stays flat.

---

## What changed (shipped)

### Engine

| Item | Location |
|------|----------|
| Shared `ShadowTokens` (`sm`–`xl`) — **strong production values** | `lib/engine/theme/shadow_tokens.dart` |
| `ShadowParser` — preset resolution + theme fallback | `lib/engine/theme/shadow_parser.dart` |
| Container / `textFormField` use shared parser | `container_renderer.dart`, `text_form_field_renderer.dart` |
| Card: `surfaceTintColor: transparent`, `shadowColor: 0x59000000` | `card_renderer.dart` |
| Optional `theme.defaultShadows` (P2, opt-in) | `mobile_theme_config.dart`, `engine_theme.dart`, renderers |
| AppMessenger toast uses `ShadowTokens.lg` | `app_messenger.dart` |
| Builder spec for `defaultShadows` | `docs/engine/builder-specs/26-default-shadows.md` |

### Production token values (strong tier)

| Preset | Color | Blur | Spread | Offset |
|--------|-------|------|--------|--------|
| `sm` | `0x33000000` | 8 | — | (0, 2) |
| `md` | `0x47000000` | 16 | 0.5 | (0, 4) |
| `lg` | `0x59000000` | 24 | 1 | (0, 6) |
| `xl` | `0x66000000` | 32 | 1.5 | (0, 8) |

### JSON (Pass A — `mobile_production_v2.json`)

| Node | Property |
|------|----------|
| `home-search-autocomplete-panel`, `search-autocomplete-panel` | `shadow: xl` |
| `home-search-field`, `search-field` | `shadow: lg` |
| `home-hero-section` | `shadow: xl` |
| `product-info-block` | `elevation: 6` |
| `cart-checkout-panel` | `elevation: 8` |
| App bars | explicit `elevation: 0` |
| Other cards | `elevation: 0` (default flat) |

Re-apply after accidental edits: `dart run tool/apply_pass_a_shadow_json.dart`

### Tests

- `test/engine/theme/shadow_parser_test.dart`
- `test/engine/shadow_diagnostic_test.dart`
- `test/engine/visual_hierarchy_pass_a_test.dart`

### Documentation

| Doc | Purpose |
|-----|---------|
| [`shadow_diagnostic_report.md`](shadow_diagnostic_report.md) | Root-cause analysis |
| [`shadow_experiment/RECOMMENDATIONS.md`](shadow_experiment/RECOMMENDATIONS.md) | BoxShadow vs elevation vs flat |
| This file | Closure + production values |

---

## Final strategy

| Surface type | Mechanism | Production value |
|--------------|-----------|------------------|
| Overlays (autocomplete) | **BoxShadow** on `container` | `xl` |
| Inputs (search fields) | **BoxShadow** on `textFormField` | `lg` |
| Hero promo | **BoxShadow** on `container` | `xl` |
| Floating cards (checkout, product info) | **Material elevation** on `card` | `8` / `6` |
| Chrome (app bar, bottom nav, buttons) | **Flat** | `elevation: 0` |
| Toasts | **BoxShadow** | `lg` via `ShadowTokens` |

Most product grid / account cards remain **flat** (`elevation: 0`) to avoid a heavy grid; bump individual nodes in JSON when a surface must float.

---

## References

- Builder spec: [`docs/engine/builder-specs/26-default-shadows.md`](../engine/builder-specs/26-default-shadows.md)
- Initial inventory (historical): [`shadow_report.md`](shadow_report.md)
