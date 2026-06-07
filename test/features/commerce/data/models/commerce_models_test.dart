import 'package:flutter_test/flutter_test.dart';
import 'package:sooq_merchant/features/commerce/data/models/apply_discount_result.dart';
import 'package:sooq_merchant/features/commerce/data/models/cart.dart';
import 'package:sooq_merchant/features/commerce/data/models/cart_line.dart';
import 'package:sooq_merchant/features/commerce/data/models/checkout_request.dart';
import 'package:sooq_merchant/features/commerce/data/models/customer_order.dart';
import 'package:sooq_merchant/features/commerce/data/models/customer_shipment_status.dart';
import 'package:sooq_merchant/features/commerce/data/models/enums/discount_type.dart';
import 'package:sooq_merchant/features/commerce/data/models/enums/order_status.dart';
import 'package:sooq_merchant/features/commerce/data/models/enums/payment_method.dart';
import 'package:sooq_merchant/features/commerce/data/models/enums/payment_status.dart';
import 'package:sooq_merchant/features/commerce/data/models/enums/shipment_status.dart';
import 'package:sooq_merchant/features/commerce/data/models/order_list_response.dart';
import 'package:sooq_merchant/features/commerce/data/models/public_payment_method.dart';
import 'package:sooq_merchant/features/commerce/data/models/shipping_cost_response.dart';

void main() {
  group('CartLine / Cart', () {
    test('fromJson round-trip', () {
      const line = CartLine(
        variantId: 'd2000000-0000-0000-0000-000000000001',
        quantity: 2,
        productTitle: 'Cotton shirt',
        variantTitle: 'M / Blue',
        unitPrice: 62500,
        thumbnailUrl: 'https://example.com/thumb.png',
      );
      final cart = Cart(items: [line]);
      final restored = Cart.fromJson(cart.toJson());
      expect(restored.items, hasLength(1));
      expect(restored.items.first.variantId, line.variantId);
      expect(restored.subtotalSyp, 125000);
      expect(restored.itemCount, 2);
    });
  });

  group('CheckoutRequest', () {
    test('fromJson matches spec §2.4 shape', () {
      final request = CheckoutRequest.fromJson({
        'items': [
          {'variantId': 'd2000000-0000-0000-0000-000000000001', 'quantity': 2},
        ],
        'shippingAddress': {
          'latitude': 33.5012,
          'longitude': 36.2901,
          'recipientName': 'أحمد علي',
          'phone': '+963999999999',
          'addressLabel': 'Al-Hamra St',
        },
        'paymentMethod': 'COD',
        'checkoutToken': 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
        'discountCode': '10OFF',
        'notesCustomer': 'Please deliver after 5pm',
        'guestEmail': 'guest@example.com',
      });
      expect(request.paymentMethod, 'COD');
      expect(request.items, hasLength(1));
      expect(request.shippingAddress.latitude, closeTo(33.5012, 0.0001));
      expect(CheckoutRequest.fromJson(request.toJson()).checkoutToken,
          request.checkoutToken);
    });
  });

  group('CustomerOrder', () {
    test('fromEnvelopeData parses place-order response', () {
      final order = CustomerOrder.fromEnvelopeData({
        'orderId': 'f281e41d-0000-0000-0000-000000000001',
        'tenantId': 'b0e061f0-0000-0000-0000-000000000001',
        'customerId': null,
        'orderNumber': 'ORD-1713091200000',
        'orderStatus': 'PENDING',
        'paymentStatus': 'UNPAID',
        'paymentMethod': 'COD',
        'currencyCode': 'SYP',
        'subtotal': 125000,
        'discountAmount': 12500,
        'taxAmount': 0,
        'shippingCost': 25000,
        'total': 137500,
        'shippingAddress': {
          'latitude': 33.5012,
          'longitude': 36.2901,
          'recipientName': 'Test',
          'phone': '+963999999999',
        },
        'placedAt': '2026-05-29T16:50:17.00093',
        'items': [
          {
            'orderItemId': 'oi-1',
            'variantId': 'd2000000-0000-0000-0000-000000000001',
            'productTitle': 'Cotton shirt',
            'variantTitle': 'M / Blue',
            'sku': 'CS-M-BLU',
            'quantity': 2,
            'unitPrice': 62500,
            'discountAmount': 0,
            'totalPrice': 125000,
          },
        ],
        'timeline': [
          {
            'timelineId': 'tl-1',
            'action': 'ORDER_CREATED',
            'actor': 'CUSTOMER',
            'details': null,
            'createdAt': '2026-05-29T16:50:17.00093',
          },
        ],
      });
      expect(order.orderStatus, OrderStatus.pending);
      expect(order.paymentStatus, PaymentStatus.unpaid);
      expect(order.paymentMethod, PaymentMethod.cod);
      expect(order.total, 137500);
      expect(order.items, hasLength(1));
    });
  });

  group('OrderListResponse', () {
    test('normalizes Spring Page envelope', () {
      final response = OrderListResponse.fromJson({
        'success': true,
        'data': {
          'content': [
            {
              'orderId': '1',
              'tenantId': 't',
              'orderNumber': 'ORD-1',
              'orderStatus': 'DELIVERED',
              'paymentStatus': 'PAID',
              'paymentMethod': 'COD',
              'subtotal': 125000,
              'discountAmount': 0,
              'taxAmount': 0,
              'total': 150000,
              'itemCount': 3,
              'placedAt': '2026-05-29T16:50:17.00093',
            },
          ],
          'totalElements': 137,
          'totalPages': 7,
          'number': 0,
          'size': 20,
          'first': true,
          'last': false,
        },
        'timestamp': 1780062656744,
      });
      expect(response.data, hasLength(1));
      expect(response.meta.total, 137);
      expect(response.data.first.orderStatus, OrderStatus.delivered);
    });
  });

  group('ShippingCostResponse', () {
    test('fromJson uses integer SYP', () {
      final quote = ShippingCostResponse.fromJson({
        'shippingCostSyp': 25000,
        'providerCode': 'DOMESTIC',
        'providerName': 'اسم شركة الشحن',
        'estimatedDeliveryHours': 48,
      });
      expect(quote.shippingCostSyp, 25000);
    });
  });

  group('ApplyDiscountResult', () {
    test('fromJson parses discount type enum', () {
      final result = ApplyDiscountResult.fromJson({
        'discountCodeId': 'c1b2',
        'code': '10OFF',
        'discountType': 'PERCENTAGE',
        'appliedAmount': 12500,
      });
      expect(result.discountType, DiscountType.percentage);
      expect(result.appliedAmount, 12500);
    });
  });

  group('PublicPaymentMethod', () {
    test('fromJson parses COD and Paymera flags', () {
      final cod = PublicPaymentMethod.fromJson({
        'providerCode': 'COD',
        'displayName': 'COD',
        'requiresRedirect': false,
        'supportsSavedCards': false,
      });
      expect(cod.requiresRedirect, isFalse);

      final paymera = PublicPaymentMethod.fromJson({
        'providerCode': 'PAYMERA',
        'displayName': 'Paymera',
        'requiresRedirect': true,
        'supportsSavedCards': true,
      });
      expect(paymera.requiresRedirect, isTrue);
    });
  });

  group('CustomerShipmentStatus', () {
    test('fromJson parses status history', () {
      final shipment = CustomerShipmentStatus.fromJson({
        'shipmentId': 's1',
        'orderId': 'o1',
        'shipmentStatus': 'IN_TRANSIT',
        'statusLabel': 'قيد التوصيل',
        'createdAt': '2026-05-29T16:50:17.00093',
        'statusHistory': [
          {'status': 'PENDING', 'timestamp': '2026-05-29T16:50:17'},
          {'status': 'IN_TRANSIT', 'timestamp': '2026-05-30T09:00:00'},
        ],
      });
      expect(shipment.shipmentStatus, ShipmentStatus.inTransit);
      expect(shipment.statusHistory, hasLength(2));
    });
  });
}
