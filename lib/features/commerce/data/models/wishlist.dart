import 'package:equatable/equatable.dart';

import 'commerce_json_helpers.dart';
import 'wishlist_item.dart';

/// Local wishlist persisted on device.
class Wishlist extends Equatable {
  const Wishlist({this.items = const []});

  final List<WishlistItem> items;

  int get count => items.length;

  bool get isEmpty => items.isEmpty;

  List<String> get productIds =>
      items.map((item) => item.productId).where((id) => id.isNotEmpty).toList();

  bool containsProduct(String productId) {
    final id = productId.trim();
    if (id.isEmpty) return false;
    return items.any((item) => item.productId == id);
  }

  factory Wishlist.fromJson(Map<String, dynamic> json) {
    return Wishlist(
      items: readCommerceList(json['items'], WishlistItem.fromJson),
    );
  }

  Map<String, dynamic> toJson() => {
        'items': items.map((item) => item.toJson()).toList(),
      };

  Wishlist copyWith({List<WishlistItem>? items}) =>
      Wishlist(items: items ?? this.items);

  @override
  List<Object?> get props => [items];
}
