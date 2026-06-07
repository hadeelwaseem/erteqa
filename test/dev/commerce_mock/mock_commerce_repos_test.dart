import 'package:flutter_test/flutter_test.dart';
import 'package:sooq_merchant/dev/commerce_mock/mock_checkout_repo.dart';
import 'package:sooq_merchant/dev/commerce_mock/mock_commerce_data.dart';
import 'package:sooq_merchant/dev/commerce_mock/mock_order_repo.dart';
import 'package:sooq_merchant/dev/commerce_mock/mock_shipping_repo.dart';
import 'package:sooq_merchant/features/commerce/data/models/checkout_item.dart';
import 'package:sooq_merchant/features/commerce/data/models/checkout_request.dart';
import 'package:sooq_merchant/features/commerce/data/models/guest_order_lookup.dart';
import 'package:sooq_merchant/features/commerce/data/models/shipping_address.dart';
import 'package:sooq_merchant/features/commerce/data/models/shipping_cost_request.dart';

void main() {
  late MockCheckoutRepo checkoutRepo;
  late MockOrderRepo orderRepo;
  late MockShippingRepo shippingRepo;

  setUp(() {
    MockCommerceData.resetForTests();
    checkoutRepo = MockCheckoutRepo();
    orderRepo = MockOrderRepo();
    shippingRepo = MockShippingRepo();
  });

  CheckoutRequest buildRequest({required String checkoutToken}) {
    return CheckoutRequest(
      items: const [
        CheckoutItem(variantId: 'var-001', quantity: 2),
        CheckoutItem(variantId: 'var-002', quantity: 1),
      ],
      shippingAddress: const ShippingAddress(
        latitude: 33.5138,
        longitude: 36.2765,
        recipientName: 'أحمد خالد',
        phone: '+963944111222',
        addressLabel: 'دمشق - المزة',
      ),
      paymentMethod: 'COD',
      checkoutToken: checkoutToken,
      discountCode: '10OFF',
      guestEmail: 'guest@example.com',
    );
  }

  test('getPaymentMethods returns COD and redirect method', () async {
    final result = await checkoutRepo.getPaymentMethods();
    result.fold(
      (failure) => fail(failure.errMessage),
      (methods) {
        expect(methods, hasLength(2));
        expect(methods.any((m) => m.providerCode == 'COD'), isTrue);
        expect(methods.any((m) => m.requiresRedirect), isTrue);
      },
    );
  });

  test('calculateShipping returns typed response with integer SYP', () async {
    final result = await checkoutRepo.calculateShipping(
      request: const ShippingCostRequest(
        originLat: 33.5,
        originLng: 36.3,
        destinationLat: 33.52,
        destinationLng: 36.28,
      ),
    );
    result.fold(
      (failure) => fail(failure.errMessage),
      (shipping) {
        expect(shipping.shippingCostSyp, isA<int>());
        expect(shipping.shippingCostSyp, greaterThan(0));
      },
    );
  });

  test('validateDiscount rejects invalid code with Left', () async {
    final result = await checkoutRepo.validateDiscount(
      code: 'BADCODE',
      subtotal: 100000,
      shippingCost: 25000,
    );

    result.fold(
      (failure) => expect(failure.errMessage, isNotEmpty),
      (_) => fail('expected failure for invalid code'),
    );
  });

  test('placeOrder is idempotent for same checkoutToken', () async {
    final request = buildRequest(checkoutToken: 'token-dup-001');

    final first = await checkoutRepo.placeOrder(request: request);
    final second = await checkoutRepo.placeOrder(request: request);

    first.fold(
      (failure) => fail(failure.errMessage),
      (orderA) {
        second.fold(
          (failure) => fail(failure.errMessage),
          (orderB) {
            expect(orderA.orderId, orderB.orderId);
            expect(orderA.orderNumber, orderB.orderNumber);
          },
        );
      },
    );
  });

  test('lookupGuestOrder succeeds for seeded guest pair', () async {
    final orderNumber = MockCommerceData.firstGuestOrderNumber();
    expect(orderNumber, isNotNull);

    final result = await checkoutRepo.lookupGuestOrder(
      lookup: GuestOrderLookup(
        orderNumber: orderNumber!,
        email: MockCommerceData.defaultGuestEmail,
      ),
    );

    result.fold(
      (failure) => fail(failure.errMessage),
      (order) => expect(order.guestEmail, MockCommerceData.defaultGuestEmail),
    );
  });

  test('getOrders returns paged response meta', () async {
    final result = await orderRepo.getOrders(page: 0, size: 2);
    result.fold(
      (failure) => fail(failure.errMessage),
      (page) {
        expect(page.success, isTrue);
        expect(page.data.length, lessThanOrEqualTo(2));
        expect(page.meta.total, greaterThanOrEqualTo(3));
      },
    );
  });

  test('cancelOrder allows confirmed and rejects delivered', () async {
    final confirmedId = MockCommerceData.firstConfirmedOrderId();
    final deliveredId = MockCommerceData.firstDeliveredOrderId();
    expect(confirmedId, isNotNull);
    expect(deliveredId, isNotNull);

    final ok = await orderRepo.cancelOrder(orderId: confirmedId!);
    ok.fold(
      (failure) => fail(failure.errMessage),
      (order) => expect(order.orderStatus.toWire(), 'CANCELLED'),
    );

    final blocked = await orderRepo.cancelOrder(orderId: deliveredId!);
    blocked.fold(
      (failure) => expect(failure.errMessage, isNotEmpty),
      (_) => fail('expected business failure when cancelling delivered order'),
    );
  });

  test('trackShipment returns Left for unknown order', () async {
    final result = await shippingRepo.trackShipment(orderId: 'ord-does-not-exist');
    result.fold(
      (failure) => expect(failure.errMessage, contains('Shipment not found')),
      (_) => fail('expected shipment lookup failure'),
    );
  });
}
