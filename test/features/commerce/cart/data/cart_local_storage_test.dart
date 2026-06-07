import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sooq_merchant/features/commerce/cart/data/datasources/cart_local_storage.dart';
import 'package:sooq_merchant/features/commerce/data/models/cart.dart';
import 'package:sooq_merchant/features/commerce/data/models/cart_line.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('save and load round-trip cart JSON', () async {
    final storage = CartLocalStorage();
    const cart = Cart(
      items: [
        CartLine(
          variantId: 'var-001',
          quantity: 2,
          productTitle: 'منتج',
          unitPrice: 15000,
        ),
      ],
    );

    await storage.save(cart);
    final loaded = await storage.load();

    expect(loaded.items, hasLength(1));
    expect(loaded.items.first.variantId, 'var-001');
    expect(loaded.items.first.quantity, 2);
    expect(loaded.subtotalSyp, 30000);
  });

  test('clear removes persisted cart', () async {
    final storage = CartLocalStorage();
    await storage.save(
      const Cart(
        items: [
          CartLine(
            variantId: 'v1',
            quantity: 1,
            productTitle: 'A',
            unitPrice: 100,
          ),
        ],
      ),
    );

    await storage.clear();
    final loaded = await storage.load();

    expect(loaded.isEmpty, isTrue);
  });

  test('missing key returns empty cart', () async {
    final storage = CartLocalStorage();
    expect((await storage.load()).isEmpty, isTrue);
  });
}
