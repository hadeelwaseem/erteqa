/// Resolves the tenant identifier for public storefront API calls.
///
/// Priority: JSON [configTenantId] → session (post-login) → JSON [configTenantSlug].
class TenantResolver {
  const TenantResolver._();

  static String? resolve({
    String? configTenantId,
    String? configTenantSlug,
    String? sessionTenantId,
  }) {
    final fromConfig = _nonEmpty(configTenantId);
    if (fromConfig != null) {
      return fromConfig;
    }

    final fromSession = _nonEmpty(sessionTenantId);
    if (fromSession != null) {
      return fromSession;
    }

    return _nonEmpty(configTenantSlug);
  }

  static String? _nonEmpty(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }
}
