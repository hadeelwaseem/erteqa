import 'package:flutter_test/flutter_test.dart';
import 'package:sooq_merchant/core/enums/generic_component_type.dart';
import 'package:sooq_merchant/features/variantscreen/data/repos/variant_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final repository = AssetVariantRepository();

  const smokeRoutes = [
    '/splash',
    '/home',
    '/auth/login',
    '/search',
  ];

  for (final route in smokeRoutes) {
    test('parses $route with synthetic scaffold root', () async {
      final config = await repository.loadVariant(
        'mobile_production_v2',
        pageRoute: route,
      );
      expect(config.root.type, GenericComponentType.scaffold);
      final pageScroll = config.root.properties['pageScroll'] as String?;
      expect(pageScroll, isNotNull);
      expect(config.root.child?.type, GenericComponentType.column);
    });
  }

  test('/splash uses centered preset for viewport-fill layout', () async {
    final config = await repository.loadVariant(
      'mobile_production_v2',
      pageRoute: '/splash',
    );
    expect(config.root.properties['pageScroll'], 'none');
    expect(config.root.properties['pageLayout'], 'centered');
    expect(config.root.child?.properties['mainAxisSize'], 'max');
  });
}
