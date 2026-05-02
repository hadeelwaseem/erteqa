import 'package:flutter/material.dart';

import '../../../config/component_config.dart';
import '../../component_renderer/component_renderer.dart';
import '../parsers/property_parsers.dart';

class IconRenderer implements ComponentRenderer {
  @override
  Widget render(
    ComponentConfig config, {
    required ComponentWidgetBuilder buildChild,
    Map<String, dynamic>? dataContext,
  }) {
    final name = config.properties['name'] as String? ?? '';
    final size = PropertyParsers.parseDouble(config.properties['size']);
    final color = PropertyParsers.parseColor(
      config.properties['color'] as String?,
    );

    return Icon(_iconFromName(name), size: size, color: color);
  }

  IconData _iconFromName(String name) {
    switch (name) {
      case 'home':
        return Icons.home;
      case 'list':
        return Icons.list;
      case 'grid_view':
        return Icons.grid_view;
      case 'settings':
        return Icons.settings;
      case 'search':
        return Icons.search;
      case 'cart':
      case 'shopping_cart':
        return Icons.shopping_cart;
      case 'favorite':
        return Icons.favorite;
      case 'person':
        return Icons.person;
      default:
        return Icons.circle;
    }
  }
}
