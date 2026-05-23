import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sooq_merchant/engine/validation/layout_constraint_validator.dart';
import 'package:sooq_merchant/features/variantscreen/data/repos/variant_repository.dart';

Future<List<String>> _loadProdPageRoutes() async {
  final jsonString = await rootBundle.loadString(
    'assets/config/mobile_production_v2.json',
  );
  final json = jsonDecode(jsonString) as Map<String, dynamic>;
  final pages = json['pages'] as List;
  return [
    for (final page in pages)
      if (page is Map<String, dynamic> && page['route'] is String)
        page['route'] as String,
  ];
}

Future<void> main() async {
  TestWidgetsFlutterBinding.ensureInitialized();

  const validator = LayoutConstraintValidator();
  final repository = AssetVariantRepository();
  final pageRoutes = await _loadProdPageRoutes();
  if (pageRoutes.isEmpty) {
    throw StateError('mobile_production_v2.json has no page routes');
  }

  for (final route in pageRoutes) {
    test('prod page $route has zero layout validator errors', () async {
      final config = await repository.loadVariant(
        'mobile_production_v2',
        pageRoute: route,
      );

      final rootProps = config.root.properties;
      final violations = validator.validate(
        config.root,
        pageScroll: rootProps['pageScroll'] as String?,
        pageLayout: rootProps['pageLayout'] as String?,
        pageRoute: rootProps['pageRoute'] as String?,
      );

      final errors = violations
          .where((v) => v.severity == LayoutViolationSeverity.error)
          .toList();
      if (errors.isNotEmpty) {
        fail(
          'Layout errors on $route:\n'
          '${errors.map((e) => '${e.code} at ${e.path}: ${e.message}').join('\n')}',
        );
      }
    });
  }
}
