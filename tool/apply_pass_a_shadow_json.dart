// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

/// Applies Pass A shadow/elevation values (strong production tier).
/// Run: dart run tool/apply_pass_a_shadow_json.dart
void main() {
  const path = 'assets/config/mobile_production_v2.json';
  final file = File(path);
  final data = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

  const shadowById = <String, String>{
    'home-search-autocomplete-panel': 'xl',
    'search-autocomplete-panel': 'xl',
    'home-hero-section': 'xl',
    'home-search-field': 'lg',
    'search-field': 'lg',
  };

  const elevationById = <String, int>{
    'cart-checkout-panel': 8,
    'product-info-block': 6,
  };

  void walk(Map<String, dynamic> node) {
    final nodeId = node['id'] as String?;
    final nodeType = node['type'] as String?;

    if (nodeId != null && shadowById.containsKey(nodeId)) {
      var style = node['style'];
      if (style is! Map<String, dynamic>) {
        style = <String, dynamic>{};
        node['style'] = style;
      }
      style['shadow'] = shadowById[nodeId];
    }

    if (nodeType == 'card') {
      var props = node['props'];
      if (props is! Map<String, dynamic>) {
        props = <String, dynamic>{};
        node['props'] = props;
      }
      if (nodeId != null && elevationById.containsKey(nodeId)) {
        props['elevation'] = elevationById[nodeId];
      } else if ((props['elevation'] as num?)?.toInt() == 6) {
        props['elevation'] = 0;
      }
    }

    final child = node['child'];
    if (child is Map<String, dynamic>) {
      walk(child);
    }

    final itemBuilder = node['itemBuilder'];
    if (itemBuilder is Map<String, dynamic>) {
      final item = itemBuilder['item'];
      if (item is Map<String, dynamic>) {
        walk(item);
      }
    }

    final children = node['children'];
    if (children is List) {
      for (final c in children) {
        if (c is Map<String, dynamic>) {
          walk(c);
        }
      }
    }
  }

  for (final page in data['pages'] as List) {
    if (page is! Map<String, dynamic>) continue;
    for (final key in ['body', 'appBar']) {
      final v = page[key];
      if (v is List) {
        for (final item in v) {
          if (item is Map<String, dynamic>) walk(item);
        }
      } else if (v is Map<String, dynamic>) {
        walk(v);
      }
    }
  }

  file.writeAsStringSync('${const JsonEncoder.withIndent('  ').convert(data)}\n');
  print('Applied Pass A shadow/elevation values to $path');
}
