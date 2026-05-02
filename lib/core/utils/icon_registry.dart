import 'package:flutter/material.dart';

/// Resolves icon name strings (from JSON) to Flutter [IconData].
///
/// Only Material icon names are supported. Add entries here when new icons
/// are referenced in JSON configs.
class IconRegistry {
  IconRegistry._();

  static const _icons = <String, IconData>{
    // Navigation
    'home': Icons.home,
    'home_outlined': Icons.home_outlined,
    'search': Icons.search,
    'menu': Icons.menu,
    'close': Icons.close,
    'back': Icons.arrow_back,
    'arrow_back': Icons.arrow_back,
    'arrow_forward': Icons.arrow_forward,

    // Commerce
    'shopping_cart': Icons.shopping_cart,
    'shopping_cart_outlined': Icons.shopping_cart_outlined,
    'shopping_bag': Icons.shopping_bag,
    'favorite': Icons.favorite,
    'favorite_outline': Icons.favorite_outline,
    'star': Icons.star,
    'star_outline': Icons.star_outline,

    // Layout
    'grid_view': Icons.grid_view,
    'list': Icons.list,
    'view_list': Icons.view_list,

    // User
    'person': Icons.person,
    'person_outline': Icons.person_outline,
    'account_circle': Icons.account_circle,

    // Actions
    'add': Icons.add,
    'delete': Icons.delete,
    'edit': Icons.edit,
    'share': Icons.share,
    'info': Icons.info,
    'settings': Icons.settings,
    'notifications': Icons.notifications,
    'notifications_outlined': Icons.notifications_outlined,

    // Media
    'image': Icons.image,
    'play_circle': Icons.play_circle,
    'videocam': Icons.videocam,

    // Category / Store
    'store': Icons.store,
    'category': Icons.category,
    'local_offer': Icons.local_offer,
    'inventory': Icons.inventory,
    'receipt': Icons.receipt,
  };

  /// Returns the [IconData] for [name], or [Icons.help_outline] if unknown.
  static IconData resolve(String? name) {
    if (name == null || name.isEmpty) return Icons.help_outline;
    return _icons[name] ?? Icons.help_outline;
  }
}
