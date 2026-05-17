import 'package:sooq_merchant/core/network/tenant_resolver.dart';

/// Runtime network settings loaded from mobile app JSON config.
class NetworkConfig {
  final String baseUrl;
  final String? tenantId;
  final String? tenantSlug;

  const NetworkConfig({
    required this.baseUrl,
    this.tenantId,
    this.tenantSlug,
  });

  /// Tenant for `X-Tenant-ID` on public product/category APIs (guest + logged-in).
  String? effectiveTenantId({String? sessionTenantId}) {
    return TenantResolver.resolve(
      configTenantId: tenantId,
      configTenantSlug: tenantSlug,
      sessionTenantId: sessionTenantId,
    );
  }

  /// Host prefix for relative asset paths (strips trailing `/api` segment).
  String get assetBaseUrl {
    final normalized = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    final apiIndex = normalized.indexOf('/api');
    if (apiIndex == -1) {
      return normalized;
    }
    return normalized.substring(0, apiIndex);
  }

  static const String defaultBaseUrl = 'https://sooq.up.railway.app';

  factory NetworkConfig.fromAppConfig({
    String? apiBaseUrl,
    String? tenantId,
    String? tenantSlug,
  }) {
    final resolvedUrl = apiBaseUrl?.trim();
    return NetworkConfig(
      baseUrl: _normalizeBaseUrl(
        resolvedUrl == null || resolvedUrl.isEmpty ? defaultBaseUrl : resolvedUrl,
      ),
      tenantId: tenantId?.trim().isEmpty == true ? null : tenantId?.trim(),
      tenantSlug: tenantSlug?.trim().isEmpty == true ? null : tenantSlug?.trim(),
    );
  }

  static String _normalizeBaseUrl(String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) {
      return defaultBaseUrl;
    }
    return trimmed.endsWith('/') ? trimmed.substring(0, trimmed.length - 1) : trimmed;
  }
}
