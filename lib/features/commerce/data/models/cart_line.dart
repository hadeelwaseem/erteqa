import 'package:equatable/equatable.dart';

import 'commerce_json_helpers.dart';

/// Local cart line (Page 1 — client-side only, no API).
class CartLine extends Equatable {
  const CartLine({
    required this.variantId,
    required this.quantity,
    required this.productTitle,
    this.variantTitle,
    required this.unitPrice,
    this.thumbnailUrl,
  });

  final String variantId;
  final int quantity;
  final String productTitle;
  final String? variantTitle;
  final int unitPrice;
  final String? thumbnailUrl;

  int get lineTotal => unitPrice * quantity;

  factory CartLine.fromJson(Map<String, dynamic> json) {
    return CartLine(
      variantId: readCommerceString(json['variantId']) ?? '',
      quantity: readCommerceInt(json['quantity'], fallback: 1),
      productTitle: readCommerceString(json['productTitle']) ?? '',
      variantTitle: readCommerceString(json['variantTitle']),
      unitPrice: readCommerceInt(json['unitPrice']),
      thumbnailUrl: readCommerceString(json['thumbnailUrl']),
    );
  }

  Map<String, dynamic> toJson() => {
        'variantId': variantId,
        'quantity': quantity,
        'productTitle': productTitle,
        if (variantTitle != null) 'variantTitle': variantTitle,
        'unitPrice': unitPrice,
        if (thumbnailUrl != null) 'thumbnailUrl': thumbnailUrl,
      };

  CartLine copyWith({
    String? variantId,
    int? quantity,
    String? productTitle,
    String? variantTitle,
    int? unitPrice,
    String? thumbnailUrl,
  }) {
    return CartLine(
      variantId: variantId ?? this.variantId,
      quantity: quantity ?? this.quantity,
      productTitle: productTitle ?? this.productTitle,
      variantTitle: variantTitle ?? this.variantTitle,
      unitPrice: unitPrice ?? this.unitPrice,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
    );
  }

  @override
  List<Object?> get props => [
        variantId,
        quantity,
        productTitle,
        variantTitle,
        unitPrice,
        thumbnailUrl,
      ];
}
