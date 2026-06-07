import 'package:equatable/equatable.dart';

import 'commerce_json_helpers.dart';

/// Line item in [CheckoutRequest] — server reprices at checkout.
class CheckoutItem extends Equatable {
  const CheckoutItem({
    required this.variantId,
    required this.quantity,
  });

  final String variantId;
  final int quantity;

  factory CheckoutItem.fromJson(Map<String, dynamic> json) {
    return CheckoutItem(
      variantId: readCommerceString(json['variantId']) ?? '',
      quantity: readCommerceInt(json['quantity'], fallback: 1),
    );
  }

  Map<String, dynamic> toJson() => {
        'variantId': variantId,
        'quantity': quantity,
      };

  @override
  List<Object?> get props => [variantId, quantity];
}
