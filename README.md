# SOOQ Merchant Mobile

Flutter-based **dynamic mobile app generator** for SOOQ merchants. UI, navigation, and theming are defined in JSON configuration; Dart provides the rendering engine and business features.

## Quick start

1. Install Flutter SDK (^3.10.4 per `pubspec.yaml`)
2. `flutter pub get`
3. `flutter run`

Active config: `mobile_production_v2` in `lib/main.dart` → `assets/config/mobile_production_v2.json`

## Documentation

| Audience | Start here |
|----------|------------|
| AI assistants / contributors | [AGENTS.md](AGENTS.md) |
| Full reference | [docs/ai/README.md](docs/ai/README.md) |

## Architecture (summary)

```
Config (JSON) → Engine (ScreenRenderer) → Flutter UI
                     ↑
              Features (auth, product APIs via VariantScreen)
```

- **Config** — `lib/config/`, `assets/config/`
- **Engine** — `lib/engine/`
- **Core** — `lib/core/` (DI, router, network)
- **Features** — `lib/features/`

## Tests

```bash
flutter test
```

See [docs/ai/11-testing.md](docs/ai/11-testing.md).

## Cursor

Project rules: `.cursor/rules/` (always-on `sooqrules.mdc` + file-scoped rules).
