import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sooq_merchant/features/variantscreen/data/repos/json_variant_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('JsonVariantRepository loads splash route from in-memory JSON', () async {
    final jsonStr = await rootBundle.loadString(
      'assets/config/mobile_production_v2.json',
    );
    final json = jsonDecode(jsonStr) as Map<String, dynamic>;

    final repository = JsonVariantRepository(json);
    final splash = await repository.loadVariant(
      'mobile_production_v2',
      pageRoute: '/splash',
    );

    expect(splash.root.type.name, 'scaffold');
    expect(splash.pageName, isNotEmpty);

    final home = await repository.loadVariant(
      'mobile_production_v2',
      pageRoute: '/home',
    );
    expect(home.root.type.name, 'scaffold');
  });
}
