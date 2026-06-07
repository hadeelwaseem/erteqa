import 'package:equatable/equatable.dart';

import 'cart_line.dart';
import 'commerce_json_helpers.dart';

/// Local shopping cart persisted on device (Page 1).
class Cart extends Equatable {
  const Cart({this.items = const []});

  final List<CartLine> items;

  int get itemCount => items.fold(0, (sum, line) => sum + line.quantity);

  int get subtotalSyp => items.fold(0, (sum, line) => sum + line.lineTotal);

  bool get isEmpty => items.isEmpty;

  factory Cart.fromJson(Map<String, dynamic> json) {
    return Cart(
      items: readCommerceList(json['items'], CartLine.fromJson),
    );
  }

  Map<String, dynamic> toJson() => {
        'items': items.map((item) => item.toJson()).toList(),
      };

  Cart copyWith({List<CartLine>? items}) => Cart(items: items ?? this.items);

  @override
  List<Object?> get props => [items];
}
