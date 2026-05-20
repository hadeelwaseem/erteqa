# 09 — Workflows

## AI must know

Follow the correct layer for each change type. When unsure, use the decision tree in `AGENTS.md`.

## Change merchant UI (layout, copy, colors)

1. Edit `assets/config/mobile_production_v2.json` (or active variant).
2. Find page by `route` in `pages[]`.
3. Modify `body` nodes (`type`, `props`, `style`, `tap`).
4. Hot restart app (config loaded at startup; page slice cached per cubit).
5. No Dart change unless missing renderer or binding.

## Add a new page/route

1. Add entry to `pages[]` with unique `id`, `route`, `title`, `body`.
2. If tab-visible: add to `navigation.tabs` OR ensure route is in shell child routes.
3. If full-screen (auth/checkout): add route to `shellExcludeRoutes`.
4. `AppRouter` picks up new route automatically from `MobileAppConfig.pageRoutes`.

## Add a new component type (engine)

1. `GenericComponentType` — new enum value in `lib/core/enums/generic_component_type.dart`.
2. Renderer class implementing `ComponentRenderer` in `lib/engine/tree/renderers/`.
3. Register in `ScreenRenderer._createDefaultRenderers`.
4. Schema entry in `component_schemas.dart`.
5. Property parsing helpers if needed in `property_parsers.dart`.
6. Unit test under `test/engine/`.
7. Document JSON `type` string in [03-engine.md](03-engine.md).

## Add a new API endpoint (feature)

1. Model in `lib/features/<feature>/data/models/`.
2. Method on repo interface + `*_impl.dart`.
3. Cubit method + state classes.
4. `getIt.registerFactory` if new cubit type.
5. If JSON-driven: extend `EngineRequestMapper` + `VariantScreen` handler.
6. Add `data.requestUrl` in JSON.
7. Repo test + cubit test in `test/features/`.

## Bind API data to a list/grid

1. Add `data` block with `requestKey` + `requestUrl` on `listView`/`gridView`.
2. Add `itemBuilder` with `type: "repeat"` and `source: "dataContext.requests.{key}.data"`.
3. Use `valuePath` / `urlPath` on child nodes (`item.field`).
4. Add `tap.navigate` with `:productId` or `:categorySlug` as needed.
5. Verify mapper lists request in debug log.

## Add navigation action

```json
"tap": {
  "type": "navigate",
  "route": "/target/:param"
}
```

Ensure target route exists in `pages[]`. Params resolve from `routeParams` or list `item`.

## Switch merchant / environment

1. Change `app.apiBaseUrl`, `tenantId`, `tenantSlug` in JSON `app` section.
2. Or swap `_kActiveConfig` in `main.dart` to another `assets/config/*.json`.

## Run tests

```bash
flutter test
flutter test test/features/product/data/repos/product_repo_impl_test.dart
```

See [11-testing.md](11-testing.md).

## Code review checklist

- [ ] UI change is JSON-first
- [ ] No business logic in `lib/engine/tree/renderers/`
- [ ] Repo returns `Either<Failure, T>`
- [ ] New types registered in `ScreenRenderer`
- [ ] No per-merchant `if (tenantSlug == ...)` UI branches

## Related

- [12-production-status.md](12-production-status.md)
