import 'package:flutter_test/flutter_test.dart';
import 'package:sooq_merchant/config/component_config.dart';
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

  test('/auth/login uses centered preset and renders body subtree', () async {
    final config = await repository.loadVariant(
      'mobile_production_v2',
      pageRoute: '/auth/login',
    );
    expect(config.root.properties['pageScroll'], 'none');
    expect(config.root.properties['pageLayout'], 'centered');

    final bodyColumn = config.root.child;
    expect(bodyColumn?.type, GenericComponentType.column);
    expect(bodyColumn?.properties['mainAxisSize'], 'max');

    ComponentConfig? expandContainer;
    for (final c in bodyColumn?.layoutChildren ?? const <ComponentConfig>[]) {
      if (c.type == GenericComponentType.container) {
        expandContainer = c;
        break;
      }
    }
    expect(expandContainer?.properties['expand'], true);

    final centerColumn = expandContainer?.child;
    expect(centerColumn?.type, GenericComponentType.column);
    expect(centerColumn?.layoutChildren, isNotEmpty);
  });
}
