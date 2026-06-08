# Converter Fixtures

Paired **web input** and **expected mobile output** for manual converter testing.

## Usage

1. Run your converter on `*.web.json`.
2. Diff output against matching `*.mobile.json` (structural — IDs may differ if algorithm matches docs).
3. Run [16-post-conversion-validation.md](../16-post-conversion-validation.md) checklist.
4. Optional: merge mobile fixture into test config and `flutter run`.

## Index

| Web | Mobile | Rules covered |
|-----|--------|---------------|
| [01-page-shell.web.json](01-page-shell.web.json) | [01-page-shell.mobile.json](01-page-shell.mobile.json) | 1.1, full envelope |
| [02-section-flex-button.web.json](02-section-flex-button.web.json) | [02-section-flex-button.mobile.json](02-section-flex-button.mobile.json) | 1.2, 2.1, 2.2 |
| [03-product-grid.web.json](03-product-grid.web.json) | [03-product-grid.mobile.json](03-product-grid.mobile.json) | 2.3, API binding |
| [04-hero.web.json](04-hero.web.json) | [04-hero.mobile.json](04-hero.mobile.json) | Hero decomposition |
| [05-cart-checkout.web.json](05-cart-checkout.web.json) | [05-cart-checkout.mobile.json](05-cart-checkout.mobile.json) | Commerce cubitCall |
| [06-full-home.web.json](06-full-home.web.json) | [06-full-home.mobile.json](06-full-home.mobile.json) | Composite page |

## Notes

- `app.tenantId` / `apiBaseUrl` in mobile fixtures use placeholder values — inject real deployment config in production.
- Fixture mobile files are **reference fragments** unless marked `fullEnvelope: true`.
