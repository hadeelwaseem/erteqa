import 'package:equatable/equatable.dart';

import 'commerce_json_helpers.dart';
import 'enums/order_status.dart';
import 'enums/payment_method.dart';
import 'enums/payment_status.dart';

/// Row in `GET /customer/orders` list (spec §5).
class OrderSummary extends Equatable {
  const OrderSummary({
    required this.orderId,
    required this.tenantId,
    this.customerId,
    required this.orderNumber,
    required this.orderStatus,
    required this.paymentStatus,
    required this.paymentMethod,
    required this.subtotal,
    required this.discountAmount,
    required this.taxAmount,
    required this.total,
    required this.itemCount,
    required this.placedAt,
  });

  final String orderId;
  final String tenantId;
  final String? customerId;
  final String orderNumber;
  final OrderStatus orderStatus;
  final PaymentStatus paymentStatus;
  final PaymentMethod paymentMethod;
  final int subtotal;
  final int discountAmount;
  final int taxAmount;
  final int total;
  final int itemCount;
  final String placedAt;

  factory OrderSummary.fromJson(Map<String, dynamic> json) {
    return OrderSummary(
      orderId: readCommerceString(json['orderId']) ?? '',
      tenantId: readCommerceString(json['tenantId']) ?? '',
      customerId: readCommerceString(json['customerId']),
      orderNumber: readCommerceString(json['orderNumber']) ?? '',
      orderStatus: OrderStatus.fromWire(json['orderStatus'] as String?),
      paymentStatus: PaymentStatus.fromWire(json['paymentStatus'] as String?),
      paymentMethod: PaymentMethod.fromWire(json['paymentMethod'] as String?),
      subtotal: readCommerceInt(json['subtotal']),
      discountAmount: readCommerceInt(json['discountAmount']),
      taxAmount: readCommerceInt(json['taxAmount']),
      total: readCommerceInt(json['total']),
      itemCount: readCommerceInt(json['itemCount']),
      placedAt: readCommerceString(json['placedAt']) ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'orderId': orderId,
        'tenantId': tenantId,
        if (customerId != null) 'customerId': customerId,
        'orderNumber': orderNumber,
        'orderStatus': orderStatus.toWire(),
        'paymentStatus': paymentStatus.toWire(),
        'paymentMethod': paymentMethod.toWire(),
        'subtotal': subtotal,
        'discountAmount': discountAmount,
        'taxAmount': taxAmount,
        'total': total,
        'itemCount': itemCount,
        'placedAt': placedAt,
      };

  @override
  List<Object?> get props => [
        orderId,
        tenantId,
        customerId,
        orderNumber,
        orderStatus,
        paymentStatus,
        paymentMethod,
        subtotal,
        discountAmount,
        taxAmount,
        total,
        itemCount,
        placedAt,
      ];
}
