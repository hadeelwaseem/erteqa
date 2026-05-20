import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sooq_merchant/engine/tree/parsers/property_parsers.dart';

void main() {
  const prodIconNames = <String, IconData>{
    'shopping_bag': Icons.shopping_bag,
    'search': Icons.search,
    'chevron_right': Icons.chevron_right,
    'grid_view': Icons.grid_view,
    'credit_card': Icons.credit_card,
    'payments': Icons.payments,
    'check_circle': Icons.check_circle,
    'error': Icons.error,
    'account_circle': Icons.account_circle,
    'local_offer': Icons.local_offer,
    'local_shipping': Icons.local_shipping,
    'inventory_2': Icons.inventory_2,
    'error_outline': Icons.error_outline,
  };

  for (final entry in prodIconNames.entries) {
    test('parseIconData(${entry.key})', () {
      expect(PropertyParsers.parseIconData(entry.key), entry.value);
    });
  }

  test('parseIconData unknown falls back to circle', () {
    expect(PropertyParsers.parseIconData('not_a_real_icon'), Icons.circle);
  });
}
