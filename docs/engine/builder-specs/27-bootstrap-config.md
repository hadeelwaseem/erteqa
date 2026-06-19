# Builder spec: Bootstrap & merchant build manifest

> **Phase:** Mobile build pipeline — Sprint 1–3  
> **Status:** `implemented-in-json` (local + remoteStorage + remoteApi + disk cache + background sync)  
> **Active config:** `mobile_production_v2` (full UI JSON unchanged)  
> **Created:** 2026-06-13  

---

## Summary

The mobile app uses a **two-layer config model**: a small **bootstrap** JSON injected at build time (merchant identity + config loading mode) and a **render JSON** (`schemaVersion`, `theme`, `navigation`, `pages` only). Bootstrap is **not** part of `mobile_production_v2.json`; CI or the builder generates it per merchant before APK build.

**Identity** (`appName`, `bundleId`, `apiBaseUrl`, tenant) lives in bootstrap only. **UI** (theme, navigation, pages) lives in render JSON. There is no top-level `app` block in render JSON.

---

## Gap vs production JSON

**Checked in** `assets/config/mobile_production_v2.json`:

| Item | Exists in prod JSON? | Evidence |
|------|----------------------|----------|
| `bootstrap.json` / bootstrap fields | No | Separate build-time artifact |
| `configMode` | No | New bootstrap-only field |
| `configUrl` | No | Remote storage URL (Sprint 2+) |
| `iconUrl` | No | CI icon download (Sprint 3+) |

Full UI JSON shape: render-only (`theme`, `navigation`, `pages`). Bootstrap holds identity fields previously duplicated in the `app` block.

---

## Builder requirements

### 1. Bootstrap JSON (`assets/config/bootstrap.json`)

**Applies to:** CI-injected file bundled in APK (not committed to template repo).

**JSON shape (authoritative):**

```json
{
  "schemaVersion": "1.0",
  "configMode": "local",
  "variantId": "mobile_production_v2",
  "appName": "SOOQ Merchant Mobile",
  "bundleId": "com.sooq.merchant.mobile",
  "apiBaseUrl": "https://sooq.up.railway.app",
  "tenantId": "3fc183e8-ac80-4b2a-8bf1-4cd6ac6ffcb1",
  "tenantSlug": "anasgoldenmer",
  "configUrl": null,
  "iconUrl": null
}
```

| Field | Type | Required | Default (mobile) | Description |
|-------|------|----------|------------------|-------------|
| `schemaVersion` | string | yes | `"1.0"` | Bootstrap contract version |
| `configMode` | string | yes | `"local"` | `local` \| `remoteStorage` \| `remoteApi` |
| `variantId` | string | yes (local) | — | Asset stem for bundled full config when `configMode=local` |
| `appName` | string | yes | — | Launcher / store display name; patched to native |
| `bundleId` | string | yes | — | Android `applicationId` + iOS bundle id |
| `apiBaseUrl` | string | yes | — | `NetworkConfig.baseUrl` |
| `tenantId` | string | yes | — | Public API tenant header |
| `tenantSlug` | string | yes | — | Public API tenant slug |
| `configUrl` | string \| null | if remoteStorage | `null` | Public URL to full `mobile-config.json` |
| `iconUrl` | string \| null | no | `null` | Merchant icon URL for CI launcher icon step |

**Dev template (committed):** `assets/config/bootstrap.local.json` — debug fallback when `bootstrap.json` is absent.

### 2. Merchant build manifest (CI input)

**Applies to:** GitHub Actions / builder webhook input (not bundled as-is).

Same fields as bootstrap plus optional release metadata:

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `version` | string | no | `--build-name` for Flutter |
| `buildNumber` | number | no | `--build-number` for Flutter |

Example: [`tool/fixtures/merchant-build.example.json`](../../../tool/fixtures/merchant-build.example.json)

### 3. Config modes

| Mode | Full config source | Builder action |
|------|-------------------|----------------|
| `local` | Bundled `assets/config/{variantId}.json` | Set `variantId`; no upload needed for CI smoke test |
| `remoteStorage` | HTTP GET `configUrl` | Upload split `mobile-config.json` to CDN; set URL in manifest |
| `remoteApi` | `GET {apiBaseUrl}/api/v1/public/mobile-config?tenantSlug=...` | Backend publishes config; set `configMode` only |

---

## Mobile implementation reference

| File | Role |
|------|------|
| `lib/config/bootstrap_config.dart` | Bootstrap model |
| `lib/config/local_asset_config_source.dart` | Bundled asset loading |
| `lib/config/remote_config_fetcher.dart` | Raw HTTP fetch (3s startup, 20s background) |
| `lib/config/remote_config_source.dart` | `AppConfigSource` wrapper over fetcher |
| `lib/config/session_config_resolver.dart` | Startup: cache → remote → asset |
| `lib/config/config_validator.dart` | Validate-before-accept |
| `lib/config/config_cache.dart` | Disk cache file per merchant |
| `lib/config/config_background_sync.dart` | Post-`runApp` cache refresh (remote modes) |
| `lib/features/variantscreen/data/repos/json_variant_repository.dart` | In-memory page JSON (SSOT) |
| `lib/engine/config_pipeline.dart` | Startup orchestration |
| `tool/split_config.dart` | Prod JSON → upload-ready `mobile-config.json` |
| `tool/apply_merchant_build.dart` | Manifest → bootstrap + native patches |

**Plan:** [`docs/ai/14-mobile-build-config-pipeline-plan.md`](../../ai/14-mobile-build-config-pipeline-plan.md)

---

## Disk cache

- **Path:** `{appDocumentsDir}/sooq/mobile-config/{tenantSlug}.json` (falls back to `variantId` if slug absent)
- **Write:** Only after `ConfigValidator` passes (startup remote win or background sync)
- **Read:** First priority at startup for remote modes
- **Delete:** Corrupt/invalid cache removed at startup; resolver falls through to remote then asset

---

## Background sync

- **When:** After `runApp()` in `launch_sooq_merchant_app.dart`, remote modes only (`remoteStorage`, `remoteApi`)
- **Timeout:** 20 seconds (non-blocking `unawaited` Future)
- **Effect:** Updates disk cache only — **next launch** uses new config; never mutates in-memory `rawConfigJson`, router, or DI mid-session

---

## Validation

- All modes: validate before accept via `ConfigValidator` (`jsonDecode` + minimal shape + `fromBootstrapAndRender`).
- `configMode: local` — bundled asset via `variantId`; `sessionSource: asset`.
- `configMode: remoteStorage` — cache → HTTP GET `configUrl` (3s) → bundled asset fallback.
- `configMode: remoteApi` — cache → `GET /api/v1/public/mobile-config?tenantSlug=...` (3s) → bundled asset fallback.
- Legacy `app` block in fetched JSON is ignored; identity comes from bootstrap only.

---

## Builder UI checklist (future)

- [ ] Export merchant build manifest from builder dashboard
- [ ] Trigger GitHub `workflow_dispatch` with manifest fields
- [ ] Upload `mobile-config.json` to storage when using `remoteStorage`
- [ ] Expose `GET /merchants/{slug}/build-manifest` for CI (Sprint 3+)
