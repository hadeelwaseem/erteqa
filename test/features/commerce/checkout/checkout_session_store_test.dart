import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sooq_merchant/features/commerce/checkout/data/datasources/checkout_session_store.dart';
import 'package:sooq_merchant/features/commerce/checkout/data/models/checkout_draft.dart';
import 'package:sooq_merchant/features/commerce/data/models/customer_order.dart';
import 'package:sooq_merchant/features/commerce/data/models/enums/order_status.dart';
import 'package:sooq_merchant/features/commerce/data/models/enums/payment_method.dart';
import 'package:sooq_merchant/features/commerce/data/models/enums/payment_status.dart';
import 'package:sooq_merchant/features/commerce/data/models/shipping_address.dart';

CustomerOrder _sampleOrder() {
  return CustomerOrder(
    orderId: 'ord-1',
    tenantId: 'tenant-1',
    orderNumber: 'SOOQ-1001',
    orderStatus: OrderStatus.pending,
    paymentStatus: PaymentStatus.pending,
    paymentMethod: PaymentMethod.cod,
    currencyCode: 'SYP',
    subtotal: 100000,
    discountAmount: 0,
    taxAmount: 0,
    shippingCost: 25000,
    total: 125000,
    shippingAddress: const ShippingAddress(
      latitude: 33.51,
      longitude: 36.27,
      recipientName: 'Test',
      phone: '+963900000000',
    ),
    placedAt: '2026-01-01T00:00:00Z',
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('save and load round-trip draft JSON', () async {
    final store = CheckoutSessionStore();
    const draft = CheckoutDraft(
      latitude: 33.5138,
      longitude: 36.2765,
      paymentMethod: 'COD',
      checkoutToken: 'token-abc',
    );

    await store.saveDraft(draft);
    final loaded = await store.loadDraft();

    expect(loaded.latitude, 33.5138);
    expect(loaded.longitude, 36.2765);
    expect(loaded.paymentMethod, 'COD');
    expect(loaded.checkoutToken, 'token-abc');
  });

  test('ensureCheckoutToken is stable across calls', () async {
    final store = CheckoutSessionStore();
    const draft = CheckoutDraft(latitude: 1, longitude: 2);

    final first = await store.ensureCheckoutToken(draft);
    final reloaded = await store.loadDraft();
    final second = await store.ensureCheckoutToken(reloaded);

    expect(first, isNotEmpty);
    expect(second, first);
  });

  test('clearAfterSuccess keeps lastOrder only', () async {
    final store = CheckoutSessionStore();
    await store.saveDraft(
      const CheckoutDraft(
        latitude: 33.5,
        longitude: 36.3,
        paymentMethod: 'COD',
        checkoutToken: 'tok',
      ),
    );

    final cleared = await store.clearAfterSuccess(lastOrder: _sampleOrder());
    expect(cleared.lastOrder?.orderNumber, 'SOOQ-1001');
    expect(cleared.latitude, isNull);
    expect(cleared.paymentMethod, isNull);

    final loaded = await store.loadDraft();
    expect(loaded.lastOrder?.orderNumber, 'SOOQ-1001');
    expect(loaded.checkoutToken, isNull);
  });

  test('startNewCheckout removes persisted draft', () async {
    final store = CheckoutSessionStore();
    await store.saveDraft(const CheckoutDraft(checkoutToken: 'x'));
    await store.startNewCheckout();
    expect((await store.loadDraft()).checkoutToken, isNull);
  });
}
