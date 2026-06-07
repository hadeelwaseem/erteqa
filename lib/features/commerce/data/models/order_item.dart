import 'package:equatable/equatable.dart';

import 'commerce_json_helpers.dart';

/// Single line on an order detail (spec §2.4 / §6).
class OrderItem extends Equatable {
  const OrderItem({
    required this.orderItemId,
    required this.variantId,
    required this.productTitle,
    this.variantTitle,
    required this.sku,
    required this.quantity,
    required this.unitPrice,
    required this.discountAmount,
    required this.totalPrice,
  });

  final String orderItemId;
  final String variantId;
  final String productTitle;
  final String? variantTitle;
  final String sku;
  final int quantity;
  final int unitPrice;
  final int discountAmount;
  final int totalPrice;

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      orderItemId: readCommerceString(json['orderItemId']) ?? '',
      variantId: readCommerceString(json['variantId']) ?? '',
      productTitle: readCommerceString(json['productTitle']) ?? '',
      variantTitle: readCommerceString(json['variantTitle']),
      sku: readCommerceString(json['sku']) ?? '',
      quantity: readCommerceInt(json['quantity'], fallback: 1),
      unitPrice: readCommerceInt(json['unitPrice']),
      discountAmount: readCommerceInt(json['discountAmount']),
      totalPrice: readCommerceInt(json['totalPrice']),
    );
  }

  Map<String, dynamic> toJson() => {
        'orderItemId': orderItemId,
        'variantId': variantId,
        'productTitle': productTitle,
        if (variantTitle != null) 'variantTitle': variantTitle,
        'sku': sku,
        'quantity': quantity,
        'unitPrice': unitPrice,
        'discountAmount': discountAmount,
        'totalPrice': totalPrice,
      };

  @override
  List<Object?> get props => [
        orderItemId,
        variantId,
        productTitle,
        variantTitle,
        sku,
        quantity,
        unitPrice,
        discountAmount,
        totalPrice,
      ];
}
