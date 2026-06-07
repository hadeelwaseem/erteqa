import 'package:equatable/equatable.dart';

import 'commerce_json_helpers.dart';
import 'enums/order_status.dart';
import 'enums/payment_method.dart';
import 'enums/payment_status.dart';
import 'order_item.dart';
import 'order_timeline_entry.dart';
import 'shipping_address.dart';

/// Full customer order detail (spec §2.4, §4, §6, §7).
class CustomerOrder extends Equatable {
  const CustomerOrder({
    required this.orderId,
    required this.tenantId,
    this.customerId,
    required this.orderNumber,
    required this.orderStatus,
    required this.paymentStatus,
    required this.paymentMethod,
    required this.currencyCode,
    required this.subtotal,
    required this.discountAmount,
    required this.taxAmount,
    required this.shippingCost,
    required this.total,
    required this.shippingAddress,
    this.notesCustomer,
    this.notesInternal,
    this.guestEmail,
    required this.placedAt,
    this.items = const [],
    this.timeline = const [],
    this.invoiceNumber,
    this.invoicePdfUrl,
  });

  final String orderId;
  final String tenantId;
  final String? customerId;
  final String orderNumber;
  final OrderStatus orderStatus;
  final PaymentStatus paymentStatus;
  final PaymentMethod paymentMethod;
  final String currencyCode;
  final int subtotal;
  final int discountAmount;
  final int taxAmount;
  final int shippingCost;
  final int total;
  final ShippingAddress shippingAddress;
  final String? notesCustomer;
  final String? notesInternal;
  final String? guestEmail;
  final String placedAt;
  final List<OrderItem> items;
  final List<OrderTimelineEntry> timeline;
  final String? invoiceNumber;
  final String? invoicePdfUrl;

  factory CustomerOrder.fromJson(Map<String, dynamic> json) {
    return CustomerOrder(
      orderId: readCommerceString(json['orderId']) ?? '',
      tenantId: readCommerceString(json['tenantId']) ?? '',
      customerId: readCommerceString(json['customerId']),
      orderNumber: readCommerceString(json['orderNumber']) ?? '',
      orderStatus: OrderStatus.fromWire(json['orderStatus'] as String?),
      paymentStatus: PaymentStatus.fromWire(json['paymentStatus'] as String?),
      paymentMethod: PaymentMethod.fromWire(json['paymentMethod'] as String?),
      currencyCode: readCommerceString(json['currencyCode']) ?? 'SYP',
      subtotal: readCommerceInt(json['subtotal']),
      discountAmount: readCommerceInt(json['discountAmount']),
      taxAmount: readCommerceInt(json['taxAmount']),
      shippingCost: readCommerceInt(json['shippingCost']),
      total: readCommerceInt(json['total']),
      shippingAddress: ShippingAddress.fromJson(
        Map<String, dynamic>.from(json['shippingAddress'] as Map? ?? {}),
      ),
      notesCustomer: readCommerceString(json['notesCustomer']),
      notesInternal: readCommerceString(json['notesInternal']),
      guestEmail: readCommerceString(json['guestEmail']),
      placedAt: readCommerceString(json['placedAt']) ?? '',
      items: readCommerceList(json['items'], OrderItem.fromJson),
      timeline: readCommerceList(json['timeline'], OrderTimelineEntry.fromJson),
      invoiceNumber: readCommerceString(json['invoiceNumber']),
      invoicePdfUrl: readCommerceString(json['invoicePdfUrl']),
    );
  }

  factory CustomerOrder.fromEnvelopeData(Map<String, dynamic> data) =>
      CustomerOrder.fromJson(data);

  Map<String, dynamic> toJson() => {
        'orderId': orderId,
        'tenantId': tenantId,
        if (customerId != null) 'customerId': customerId,
        'orderNumber': orderNumber,
        'orderStatus': orderStatus.toWire(),
        'paymentStatus': paymentStatus.toWire(),
        'paymentMethod': paymentMethod.toWire(),
        'currencyCode': currencyCode,
        'subtotal': subtotal,
        'discountAmount': discountAmount,
        'taxAmount': taxAmount,
        'shippingCost': shippingCost,
        'total': total,
        'shippingAddress': shippingAddress.toJson(),
        if (notesCustomer != null) 'notesCustomer': notesCustomer,
        if (notesInternal != null) 'notesInternal': notesInternal,
        if (guestEmail != null) 'guestEmail': guestEmail,
        'placedAt': placedAt,
        'items': items.map((item) => item.toJson()).toList(),
        'timeline': timeline.map((entry) => entry.toJson()).toList(),
        if (invoiceNumber != null) 'invoiceNumber': invoiceNumber,
        if (invoicePdfUrl != null) 'invoicePdfUrl': invoicePdfUrl,
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
        currencyCode,
        subtotal,
        discountAmount,
        taxAmount,
        shippingCost,
        total,
        shippingAddress,
        notesCustomer,
        notesInternal,
        guestEmail,
        placedAt,
        items,
        timeline,
        invoiceNumber,
        invoicePdfUrl,
      ];
}
