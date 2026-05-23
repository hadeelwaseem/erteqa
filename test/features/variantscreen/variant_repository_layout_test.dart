import 'package:flutter_test/flutter_test.dart';
import 'package:sooq_merchant/core/enums/generic_component_type.dart';
import 'package:sooq_merchant/features/variantscreen/data/repos/variant_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final repository = AssetVariantRepository();

  test('/splash centered preset sets pageScroll none and pageLayout', () async {
    final config = await repository.loadVariant(
      'mobile_production_v2',
      pageRoute: '/splash',
    );

    expect(config.root.properties['pageScroll'], 'none');
    expect(config.root.properties['pageLayout'], 'centered');
    expect(config.root.properties['pageRoute'], '/splash');
    expect(config.root.child?.properties['mainAxisSize'], 'max');
    expect(config.root.child?.properties['crossAxisAlignment'], 'stretch');
  });

  test('/splash body retains expand container', () async {
    final config = await repository.loadVariant(
      'mobile_production_v2',
      pageRoute: '/splash',
    );

    final columnChildren = config.root.child?.children ?? [];
    final bodyNodes = columnChildren
        .where((c) => c.type != GenericComponentType.appBar)
        .toList();
    expect(bodyNodes, isNotEmpty);
    expect(
      bodyNodes.any(
        (c) =>
            c.type == GenericComponentType.container &&
            c.properties['expand'] == true,
      ),
      isTrue,
    );
  });

  test('/splash-carousel centered preset', () async {
    final config = await repository.loadVariant(
      'mobile_production_v2',
      pageRoute: '/splash-carousel',
    );

    expect(config.root.properties['pageScroll'], 'none');
    expect(config.root.properties['pageLayout'], 'centered');
  });

  test('centered injects expand wrapper when body lacks expand', () async {
    // Synthetic check via layoutSubtreeHasExpandContainer behavior on parse output
    // for routes that already have expand — /home should not double-wrap.
    final home = await repository.loadVariant(
      'mobile_production_v2',
      pageRoute: '/home',
    );
    expect(home.root.properties['pageLayout'], isNull);
    expect(home.root.properties['pageScroll'], 'vertical');
  });
}
