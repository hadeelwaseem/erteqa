/// HTTP headers for public storefront/commerce API calls.
///
/// Spec text uses `X-Tenant-Id`; the working catalog client sends `X-Tenant-ID`
/// — keep that wire format for backend parity with [ProductRepoImpl].
class TenantHeaders {
  TenantHeaders._();

  static const String tenantHeaderKey = 'X-Tenant-ID';

  /// Headers for `/api/v1/public/*` endpoints (no Authorization).
  static Map<String, String> buildPublicHeaders({String? tenantId}) {
    final headers = <String, String>{'Accept': 'application/json'};
    final resolved = tenantId?.trim();
    if (resolved != null && resolved.isNotEmpty) {
      headers[tenantHeaderKey] = resolved;
    }
    return headers;
  }
}
