# Strong shadow experiment (archived)

**Status:** Closed — experiment values reverted; production tokens applied.  
**See:** [`../shadow_audit_summary.md`](../shadow_audit_summary.md) for final state and strategy.

This folder retains the experiment analysis and architecture recommendations used during the audit. Device screenshots under `after/` are from the strong-shadow validation branch and are **not** the production baseline.

## Documents

| File | Purpose |
|------|---------|
| [`RECOMMENDATIONS.md`](RECOMMENDATIONS.md) | BoxShadow vs Material elevation policy (still valid) |
| [`after/*.png`](after/) | Device screenshots from experiment branch (reference only) |

## Production reference

- Tokens: `lib/engine/theme/shadow_tokens.dart`
- Pass A JSON helper: `dart run tool/apply_pass_a_shadow_json.dart`
- Tests: `test/engine/shadow_diagnostic_test.dart`, `test/engine/visual_hierarchy_pass_a_test.dart`
