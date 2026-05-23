# Temporary mock product APIs (Phase 0)

Purpose: Provide in-memory product endpoints while backend product APIs are unavailable.

Files:
- `product_mock_config.dart` — feature toggle and timings
- `mock_product_data.dart` — sample products, categories and helper factories
- `mock_product_repo.dart` — implements `ProductRepo` returning sample data (no HTTP)

Enable / disable

Set `ProductMockConfig.enabled = true` to use the mock repo. Set to `false` to use the real `ProductRepoImpl`.

Cleanup

A helper script `scripts/remove_product_mock.ps1` will be provided to remove `lib/dev/product_mock/` and revert `service_locator.dart` to point to the real repo.

Notes

- This mock mirrors the production `ProductRepo` contract and returns `Either<Failure, T>` like real repos.
- **No SOOQ HTTP** — lists/search/detail come from memory, not `sooq.up.railway.app`.
- **Images** — absolute HTTPS URLs in `mock_product_data.dart` ([placehold.co](https://placehold.co) placeholders), same field shapes as the live API (`primaryImageUrl`, `image`, `imageUrl`). Do not use picsum.photos for mock — many devices get CDN "Global locked" / HTTP 403. Relative `/uploads/...` paths resolve via `NetworkConfig.assetBaseUrl` when the backend is used.
- To change demo photos, edit the URL lists in `mock_product_data.dart` (verify one URL loads in the device browser first).
- Tenant ID parameter is accepted but ignored in Phase 0.
- Pagination and search implement simple, deterministic in-memory behavior for UI testing.
