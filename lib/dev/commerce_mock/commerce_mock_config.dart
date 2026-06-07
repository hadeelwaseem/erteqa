/// TEMPORARY — remove when commerce backend APIs are available.
class CommerceMockConfig {
  CommerceMockConfig._();

  /// Set to `false` once checkout/order/shipping APIs are wired.
  static const bool enabled = true;

  /// Simulated network latency (kept in sync with other mock modules).
  static const Duration requestDelay = Duration(milliseconds: 400);
}
