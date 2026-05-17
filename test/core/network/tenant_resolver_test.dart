import 'package:flutter_test/flutter_test.dart';
import 'package:sooq_merchant/core/network/network_config.dart';
import 'package:sooq_merchant/core/network/tenant_resolver.dart';

void main() {
  group('TenantResolver', () {
    test('prefers config tenantId over session and slug', () {
      expect(
        TenantResolver.resolve(
          configTenantId: 'config-uuid',
          configTenantSlug: 'store-a',
          sessionTenantId: 'session-uuid',
        ),
        'config-uuid',
      );
    });

    test('uses session tenantId when config tenantId is empty', () {
      expect(
        TenantResolver.resolve(
          configTenantId: '',
          configTenantSlug: 'store-a',
          sessionTenantId: 'session-uuid',
        ),
        'session-uuid',
      );
    });

    test('falls back to config tenantSlug for guest flow', () {
      expect(
        TenantResolver.resolve(
          configTenantSlug: 'anasgoldenmer',
        ),
        'anasgoldenmer',
      );
    });
  });

  group('NetworkConfig.effectiveTenantId', () {
    test('resolves from config fields and optional session', () {
      final network = NetworkConfig.fromAppConfig(
        apiBaseUrl: 'https://api.example.com',
        tenantId: 'tenant-uuid',
        tenantSlug: 'store-a',
      );

      expect(
        network.effectiveTenantId(sessionTenantId: 'other'),
        'tenant-uuid',
      );
    });
  });
}
