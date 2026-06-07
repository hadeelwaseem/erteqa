import 'package:sooq_merchant/features/commerce/data/models/checkout_request.dart';
import 'package:sooq_merchant/features/commerce/data/models/enums/order_status.dart';
import 'package:sooq_merchant/features/commerce/data/models/enums/payment_method.dart';
import 'package:sooq_merchant/features/commerce/data/models/enums/payment_status.dart';
import 'package:sooq_merchant/features/commerce/data/models/enums/shipment_status.dart';
import 'package:sooq_merchant/features/commerce/data/models/enums/timeline_actor.dart';
import 'package:sooq_merchant/features/commerce/data/models/shipping_cost_request.dart';

class MockCommerceData {
  MockCommerceData._();

  static const String tenantId = 'tenant-demo';
  static const String defaultGuestEmail = 'guest@example.com';
  static const int _shippingCostSyp = 25000;

  static int _orderSeq = 1005;
  static bool _initialized = false;

  static final Map<String, Map<String, dynamic>> _ordersById = {};
  static final Map<String, String> _idempotentOrderIdByToken = {};

  static void resetForTests() {
    _orderSeq = 1005;
    _initialized = false;
    _ordersById.clear();
    _idempotentOrderIdByToken.clear();
  }

  static Map<String, dynamic> paymentMethodsEnvelope() {
    return {
      'success': true,
      'message': 'OK',
      'data': [
        {
          'providerCode': PaymentMethod.cod.toWire(),
          'displayName': 'الدفع عند الاستلام',
          'requiresRedirect': false,
          'supportsSavedCards': false,
        },
        {
          'providerCode': PaymentMethod.paymera.toWire(),
          'displayName': 'Paymera',
          'requiresRedirect': true,
          'supportsSavedCards': false,
        },
      ],
      'timestamp': DateTime.now().toUtc().millisecondsSinceEpoch,
    };
  }

  static Map<String, dynamic> shippingCostEnvelope({
    required ShippingCostRequest request,
  }) {
    return {
      'success': true,
      'message': 'OK',
      'data': {
        'shippingCostSyp': _shippingCostSyp,
        'providerCode': 'LOCAL_COURIER',
        'providerName': 'الشحن الداخلي',
        'estimatedDeliveryHours': _estimatedHours(request),
      },
      'timestamp': DateTime.now().toUtc().millisecondsSinceEpoch,
    };
  }

  static Map<String, dynamic> discountEnvelope({
    required String code,
    required int subtotal,
  }) {
    final applied = (subtotal * 0.1).round();
    return {
      'success': true,
      'message': 'تم تطبيق الخصم',
      'data': {
        'discountCodeId': 'disc-10off',
        'code': code.toUpperCase(),
        'discountType': 'PERCENTAGE',
        'appliedAmount': applied,
      },
      'timestamp': DateTime.now().toUtc().millisecondsSinceEpoch,
    };
  }

  static Map<String, dynamic> placeOrderEnvelope({
    required CheckoutRequest request,
  }) {
    _initOnce();

    final existingOrderId = _idempotentOrderIdByToken[request.checkoutToken];
    if (existingOrderId != null && _ordersById.containsKey(existingOrderId)) {
      return _singleOrderEnvelope(_ordersById[existingOrderId]!);
    }

    final nextOrderId = 'ord-mock-${_orderSeq++}';
    final orderNumber = 'SOQ-${DateTime.now().year}-${_orderSeq.toString().padLeft(4, '0')}';
    final itemCount = request.items.fold<int>(0, (sum, item) => sum + item.quantity);
    final subtotal = request.items.fold<int>(
      0,
      (sum, item) =>
          sum + (_unitPriceForVariant(item.variantId) * item.quantity),
    );
    final discountAmount = request.discountCode?.toUpperCase() == '10OFF'
        ? (subtotal * 0.1).round()
        : 0;
    final taxAmount = 0;
    final total = subtotal - discountAmount + _shippingCostSyp + taxAmount;

    final now = DateTime.now().toUtc().toIso8601String();
    final orderMap = <String, dynamic>{
      'orderId': nextOrderId,
      'tenantId': tenantId,
      'customerId': 'cust-mock-1',
      'orderNumber': orderNumber,
      'orderStatus': OrderStatus.pending.toWire(),
      'paymentStatus': PaymentStatus.unpaid.toWire(),
      'paymentMethod': request.paymentMethod,
      'currencyCode': 'SYP',
      'subtotal': subtotal,
      'discountAmount': discountAmount,
      'taxAmount': taxAmount,
      'shippingCost': _shippingCostSyp,
      'total': total,
      'shippingAddress': request.shippingAddress.toJson(),
      if (request.notesCustomer != null) 'notesCustomer': request.notesCustomer,
      if (request.guestEmail != null) 'guestEmail': request.guestEmail,
      'placedAt': now,
      'items': [
        for (final item in request.items)
          {
            'orderItemId': 'itm-${item.variantId}',
            'variantId': item.variantId,
            'productTitle': _productTitleForVariant(item.variantId),
            'variantTitle': _variantTitleFor(item.variantId),
            'sku': 'SKU-${item.variantId}',
            'quantity': item.quantity,
            'unitPrice': _unitPriceForVariant(item.variantId),
            'discountAmount': 0,
            'totalPrice': _unitPriceForVariant(item.variantId) * item.quantity,
          },
      ],
      'timeline': [
        {
          'timelineId': 'tl-$nextOrderId-created',
          'action': 'ORDER_PLACED',
          'actor': TimelineActor.customer.toWire(),
          'details': 'تم استلام الطلب',
          'createdAt': now,
        },
      ],
      'invoiceNumber': 'INV-${_orderSeq.toString().padLeft(6, '0')}',
      'invoicePdfUrl': 'https://example.com/invoice/$nextOrderId.pdf',
      'itemCount': itemCount,
    };

    _ordersById[nextOrderId] = orderMap;
    _idempotentOrderIdByToken[request.checkoutToken] = nextOrderId;
    return _singleOrderEnvelope(orderMap);
  }

  static Map<String, dynamic>? lookupGuestOrderEnvelope({
    required String orderNumber,
    required String email,
  }) {
    _initOnce();
    final lowerEmail = email.trim().toLowerCase();
    for (final order in _ordersById.values) {
      final sameNumber = (order['orderNumber'] as String?) == orderNumber;
      final guest = (order['guestEmail'] as String?)?.trim().toLowerCase();
      if (sameNumber && guest == lowerEmail) {
        return _singleOrderEnvelope(order);
      }
    }
    return null;
  }

  static Map<String, dynamic> ordersPageEnvelope({
    required int page,
    required int size,
    String? status,
  }) {
    _initOnce();
    final normalizedStatus = status?.trim();
    final all = _ordersById.values.toList()
      ..sort((a, b) => (b['placedAt'] as String).compareTo(a['placedAt'] as String));

    final filtered = normalizedStatus == null || normalizedStatus.isEmpty
        ? all
        : all
            .where((order) => order['orderStatus'] == normalizedStatus)
            .toList();

    final start = page * size;
    final endExclusive = start + size;
    final pageItems = start >= filtered.length
        ? <Map<String, dynamic>>[]
        : filtered.sublist(
            start,
            endExclusive > filtered.length ? filtered.length : endExclusive,
          );

    final content = pageItems
        .map(
          (order) => {
            'orderId': order['orderId'],
            'tenantId': order['tenantId'],
            'customerId': order['customerId'],
            'orderNumber': order['orderNumber'],
            'orderStatus': order['orderStatus'],
            'paymentStatus': order['paymentStatus'],
            'paymentMethod': order['paymentMethod'],
            'subtotal': order['subtotal'],
            'discountAmount': order['discountAmount'],
            'taxAmount': order['taxAmount'],
            'total': order['total'],
            'itemCount': order['itemCount'] ?? 0,
            'placedAt': order['placedAt'],
          },
        )
        .toList();

    final totalPages = size == 0 ? 1 : (filtered.length / size).ceil();

    return {
      'success': true,
      'message': 'OK',
      'data': {
        'content': content,
        'number': page,
        'size': size,
        'totalElements': filtered.length,
        'totalPages': totalPages,
        'first': page == 0,
        'last': page >= (totalPages - 1),
      },
      'timestamp': DateTime.now().toUtc().millisecondsSinceEpoch,
    };
  }

  static Map<String, dynamic>? orderDetailEnvelope(String orderId) {
    _initOnce();
    final order = _ordersById[orderId];
    if (order == null) return null;
    return _singleOrderEnvelope(order);
  }

  static Map<String, dynamic>? cancelOrderEnvelope(
    String orderId, {
    String? reason,
  }) {
    _initOnce();
    final order = _ordersById[orderId];
    if (order == null) return null;
    final status = order['orderStatus'] as String?;
    final cancellable = status == OrderStatus.pending.toWire() ||
        status == OrderStatus.confirmed.toWire();
    if (!cancellable) return null;

    final now = DateTime.now().toUtc().toIso8601String();
    final timeline = List<Map<String, dynamic>>.from(order['timeline'] as List);
    timeline.add({
      'timelineId': 'tl-$orderId-cancelled',
      'action': 'ORDER_CANCELLED',
      'actor': TimelineActor.customer.toWire(),
      'details': reason ?? 'إلغاء من العميل',
      'createdAt': now,
    });

    final next = <String, dynamic>{
      ...order,
      'orderStatus': OrderStatus.cancelled.toWire(),
      'timeline': timeline,
    };
    _ordersById[orderId] = next;
    return _singleOrderEnvelope(next);
  }

  static Map<String, dynamic>? invoiceEnvelope(String orderId) {
    _initOnce();
    final order = _ordersById[orderId];
    if (order == null) return null;
    return {
      'success': true,
      'message': 'OK',
      'data': {
        'invoiceId': 'inv-$orderId',
        'orderId': orderId,
        'invoiceNumber': order['invoiceNumber'] ?? 'INV-NA',
        'pdfUrl': order['invoicePdfUrl'] ?? 'https://example.com/invoice/$orderId.pdf',
        'generatedAt': DateTime.now().toUtc().toIso8601String(),
      },
      'timestamp': DateTime.now().toUtc().millisecondsSinceEpoch,
    };
  }

  static Map<String, dynamic>? shipmentEnvelope(String orderId) {
    _initOnce();
    final order = _ordersById[orderId];
    if (order == null) return null;
    final status = OrderStatus.fromWire(order['orderStatus'] as String?);
    if (status == OrderStatus.pending) {
      return null;
    }
    final now = DateTime.now().toUtc();
    return {
      'success': true,
      'message': 'OK',
      'data': {
        'shipmentId': 'shp-$orderId',
        'orderId': orderId,
        'shipmentStatus': ShipmentStatus.inTransit.toWire(),
        'statusLabel': 'قيد التوصيل',
        'carrierTrackingUrl': 'https://example.com/track/$orderId',
        'createdAt': now.subtract(const Duration(days: 1)).toIso8601String(),
        'statusHistory': [
          {
            'status': ShipmentStatus.pickedUp.toWire(),
            'timestamp': now.subtract(const Duration(hours: 18)).toIso8601String(),
          },
          {
            'status': ShipmentStatus.inTransit.toWire(),
            'timestamp': now.subtract(const Duration(hours: 4)).toIso8601String(),
          },
        ],
      },
      'timestamp': now.millisecondsSinceEpoch,
    };
  }

  static String? firstOrderId() {
    _initOnce();
    if (_ordersById.isEmpty) return null;
    return _ordersById.keys.first;
  }

  static String? firstGuestOrderNumber() {
    _initOnce();
    for (final order in _ordersById.values) {
      if ((order['guestEmail'] as String?)?.isNotEmpty == true) {
        return order['orderNumber'] as String?;
      }
    }
    return null;
  }

  static String? firstConfirmedOrderId() {
    _initOnce();
    return _ordersById.values
        .firstWhere(
          (order) => order['orderStatus'] == OrderStatus.confirmed.toWire(),
          orElse: () => const <String, dynamic>{},
        )['orderId'] as String?;
  }

  static String? firstDeliveredOrderId() {
    _initOnce();
    return _ordersById.values
        .firstWhere(
          (order) => order['orderStatus'] == OrderStatus.delivered.toWire(),
          orElse: () => const <String, dynamic>{},
        )['orderId'] as String?;
  }

  static Map<String, dynamic> _singleOrderEnvelope(Map<String, dynamic> order) {
    return {
      'success': true,
      'message': 'OK',
      'data': order,
      'timestamp': DateTime.now().toUtc().millisecondsSinceEpoch,
    };
  }

  static int _estimatedHours(ShippingCostRequest request) {
    final latDiff = (request.originLat - request.destinationLat).abs();
    final lngDiff = (request.originLng - request.destinationLng).abs();
    final distanceFactor = (latDiff + lngDiff) * 10;
    final base = 6 + distanceFactor.round();
    return base.clamp(4, 48);
  }

  static int _unitPriceForVariant(String variantId) {
    if (variantId.endsWith('2')) return 35000;
    return 45000;
  }

  static String _productTitleForVariant(String variantId) {
    if (variantId.endsWith('2')) return 'شاحن سريع';
    return 'سماعات لاسلكية';
  }

  static String _variantTitleFor(String variantId) {
    if (variantId.endsWith('2')) return 'سريع';
    return 'أسود';
  }

  static void _initOnce() {
    if (_initialized) return;
    _initialized = true;
    for (final order in _seedOrders()) {
      _ordersById[order['orderId'] as String] = order;
    }
  }

  static List<Map<String, dynamic>> _seedOrders() {
    const now = '2026-06-01T09:00:00.000Z';
    return [
      _seedOrder(
        orderId: 'ord-mock-1001',
        orderNumber: 'SOQ-2026-1001',
        status: OrderStatus.pending,
        paymentStatus: PaymentStatus.unpaid,
        paymentMethod: PaymentMethod.cod,
        subtotal: 125000,
        discountAmount: 12500,
        shippingCost: 25000,
        total: 137500,
        placedAt: now,
        guestEmail: defaultGuestEmail,
      ),
      _seedOrder(
        orderId: 'ord-mock-1002',
        orderNumber: 'SOQ-2026-1002',
        status: OrderStatus.confirmed,
        paymentStatus: PaymentStatus.pending,
        paymentMethod: PaymentMethod.paymera,
        subtotal: 210000,
        discountAmount: 0,
        shippingCost: 25000,
        total: 235000,
        placedAt: '2026-05-30T14:20:00.000Z',
      ),
      _seedOrder(
        orderId: 'ord-mock-1003',
        orderNumber: 'SOQ-2026-1003',
        status: OrderStatus.delivered,
        paymentStatus: PaymentStatus.paid,
        paymentMethod: PaymentMethod.cod,
        subtotal: 98000,
        discountAmount: 0,
        shippingCost: 18000,
        total: 116000,
        placedAt: '2026-05-29T11:10:00.000Z',
      ),
      _seedOrder(
        orderId: 'ord-mock-1004',
        orderNumber: 'SOQ-2026-1004',
        status: OrderStatus.cancelled,
        paymentStatus: PaymentStatus.refunded,
        paymentMethod: PaymentMethod.paymera,
        subtotal: 150000,
        discountAmount: 15000,
        shippingCost: 20000,
        total: 155000,
        placedAt: '2026-05-25T08:40:00.000Z',
      ),
    ];
  }

  static Map<String, dynamic> _seedOrder({
    required String orderId,
    required String orderNumber,
    required OrderStatus status,
    required PaymentStatus paymentStatus,
    required PaymentMethod paymentMethod,
    required int subtotal,
    required int discountAmount,
    required int shippingCost,
    required int total,
    required String placedAt,
    String? guestEmail,
  }) {
    final itemA = subtotal ~/ 2;
    final itemB = subtotal - itemA;
    return {
      'orderId': orderId,
      'tenantId': tenantId,
      'customerId': 'cust-mock-1',
      'orderNumber': orderNumber,
      'orderStatus': status.toWire(),
      'paymentStatus': paymentStatus.toWire(),
      'paymentMethod': paymentMethod.toWire(),
      'currencyCode': 'SYP',
      'subtotal': subtotal,
      'discountAmount': discountAmount,
      'taxAmount': 0,
      'shippingCost': shippingCost,
      'total': total,
      'shippingAddress': {
        'latitude': 33.5138,
        'longitude': 36.2765,
        'recipientName': 'أحمد خالد',
        'phone': '+963944111222',
        'addressLabel': 'دمشق - المزة',
      },
      if (guestEmail != null) 'guestEmail': guestEmail,
      'placedAt': placedAt,
      'items': [
        {
          'orderItemId': 'itm-$orderId-1',
          'variantId': 'var-$orderId-1',
          'productTitle': 'سماعات لاسلكية',
          'variantTitle': 'أسود',
          'sku': 'SKU-$orderId-1',
          'quantity': 1,
          'unitPrice': itemA,
          'discountAmount': 0,
          'totalPrice': itemA,
        },
        {
          'orderItemId': 'itm-$orderId-2',
          'variantId': 'var-$orderId-2',
          'productTitle': 'شاحن سريع',
          'sku': 'SKU-$orderId-2',
          'quantity': 1,
          'unitPrice': itemB,
          'discountAmount': 0,
          'totalPrice': itemB,
        },
      ],
      'timeline': [
        {
          'timelineId': 'tl-$orderId-1',
          'action': 'ORDER_PLACED',
          'actor': TimelineActor.customer.toWire(),
          'details': 'تم إنشاء الطلب',
          'createdAt': placedAt,
        },
      ],
      'invoiceNumber': 'INV-$orderNumber',
      'invoicePdfUrl': 'https://example.com/invoice/$orderId.pdf',
      'itemCount': 2,
    };
  }
}
