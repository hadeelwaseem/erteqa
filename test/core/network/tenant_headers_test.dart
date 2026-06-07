import 'package:flutter_test/flutter_test.dart';
import 'package:sooq_merchant/core/network/tenant_headers.dart';

void main() {
  group('TenantHeaders.buildPublicHeaders', () {
    test('includes Accept always', () {
      final headers = TenantHeaders.buildPublicHeaders();
      expect(headers['Accept'], 'application/json');
    });

    test('includes X-Tenant-ID when tenantId provided', () {
      final headers = TenantHeaders.buildPublicHeaders(
        tenantId: 'b0e061f0-0000-0000-0000-000000000001',
      );
      expect(
        headers[TenantHeaders.tenantHeaderKey],
        'b0e061f0-0000-0000-0000-000000000001',
      );
    });

    test('omits tenant header when blank', () {
      final headers = TenantHeaders.buildPublicHeaders(tenantId: '  ');
      expect(headers.containsKey(TenantHeaders.tenantHeaderKey), isFalse);
    });
  });
}
