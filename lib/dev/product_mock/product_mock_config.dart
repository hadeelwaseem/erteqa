/// TEMPORARY — remove when backend product APIs are available.
///
/// See [README.md](README.md) and `scripts/remove_product_mock.ps1`.
class ProductMockConfig {
  ProductMockConfig._();

  /// Set to `false` to use real [ProductRepoImpl] without deleting mock files.
  static const bool enabled = true;

  /// Simulated network latency (matches "real" feel while offline).
  static const Duration requestDelay = Duration(milliseconds: 400);

  /// Number of sample products to generate in mock dataset.
  static const int sampleProductCount = 15;

  /// Number of sample categories to generate in mock dataset.
  static const int sampleCategoryCount = 2;

  /// Default page size for paginated requests.
  static const int defaultPageSize = 20;

  /// Message returned from mock search when no results (same copy pattern as API).
  static const String noResultsMessage =
      'No products found matching your search';
}
