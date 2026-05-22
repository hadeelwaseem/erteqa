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
- Tenant ID parameter is accepted but ignored in Phase 0.
- Pagination and search implement simple, deterministic in-memory behavior for UI testing.
