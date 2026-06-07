import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sooq_merchant/core/cubits/token_cubit/token_cubit.dart';
import 'package:sooq_merchant/core/errors/failures.dart';
import 'package:sooq_merchant/core/network/auth_token_storage.dart';
import 'package:sooq_merchant/dev/commerce_mock/mock_checkout_repo.dart';
import 'package:sooq_merchant/dev/commerce_mock/mock_commerce_data.dart';
import 'package:sooq_merchant/features/commerce/cart/data/repos/cart_repo.dart';
import 'package:sooq_merchant/features/commerce/cart/presentation/manager/cart_cubit/cart_cubit.dart';
import 'package:sooq_merchant/features/commerce/cart/presentation/manager/cart_cubit/cart_state.dart';
import 'package:sooq_merchant/features/commerce/checkout/data/datasources/checkout_session_store.dart';
import 'package:sooq_merchant/features/commerce/checkout/data/models/checkout_draft.dart';
import 'package:sooq_merchant/features/commerce/checkout/presentation/manager/checkout_cubit/checkout_cubit.dart';
import 'package:sooq_merchant/features/commerce/checkout/presentation/manager/checkout_cubit/checkout_state.dart';
import 'package:sooq_merchant/features/commerce/data/models/cart.dart';
import 'package:sooq_merchant/features/commerce/data/models/customer_order.dart';
import 'package:sooq_merchant/features/commerce/data/models/shipping_address.dart';
import 'package:sooq_merchant/features/commerce/data/models/shipping_cost_response.dart';

class _MemoryCartRepo implements CartRepo {
  Cart _cart = const Cart();

  @override
  Future<Either<Failure, Cart>> clear() async {
    _cart = const Cart();
    return Right(_cart);
  }

  @override
  Future<Either<Failure, Cart>> load() async => Right(_cart);

  @override
  Future<Either<Failure, Cart>> save(Cart cart) async {
    _cart = cart;
    return Right(cart);
  }
}

class _MemoryTokenStorage implements AuthTokenStorage {
  @override
  Future<void> clearTokens() async {}

  @override
  Future<String?> readAccessToken() async => null;

  @override
  Future<DateTime?> readExpiresAt() async => null;

  @override
  Future<String?> readRefreshToken() async => null;

  @override
  Future<String?> readTenantId() async => null;

  @override
  Future<AuthTokenBundle> readTokenBundle() async =>
      const AuthTokenBundle();

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    DateTime? expiresAt,
    String? tenantId,
  }) async {}
}

class _MemoryCheckoutSessionStore extends CheckoutSessionStore {
  _MemoryCheckoutSessionStore(this._draft);

  CheckoutDraft _draft;

  @override
  Future<CheckoutDraft> loadDraft() async => _draft;

  @override
  Future<void> saveDraft(CheckoutDraft draft) async {
    _draft = draft;
  }

  @override
  Future<String> ensureCheckoutToken(CheckoutDraft draft) async {
    final token = draft.checkoutToken ?? 'generated-token';
    _draft = draft.copyWith(checkoutToken: token);
    return token;
  }

  @override
  Future<CheckoutDraft> clearAfterSuccess({
    required CustomerOrder lastOrder,
  }) async {
    _draft = CheckoutDraft(lastOrder: lastOrder);
    return _draft;
  }
}

void main() {
  late MockCheckoutRepo checkoutRepo;
  late _MemoryCartRepo cartRepo;
  late CartCubit cartCubit;
  late TokenCubit tokenCubit;
  late _MemoryCheckoutSessionStore sessionStore;
  late CheckoutCubit cubit;

  Future<void> seedDraft(CheckoutDraft draft) async {
    sessionStore._draft = draft;
    await cubit.loadDraft();
  }

  setUp(() {
    MockCommerceData.resetForTests();
    checkoutRepo = MockCheckoutRepo();
    cartRepo = _MemoryCartRepo();
    cartCubit = CartCubit(cartRepo);
    tokenCubit = TokenCubit(_MemoryTokenStorage());
    sessionStore = _MemoryCheckoutSessionStore(const CheckoutDraft());
    cubit = CheckoutCubit(checkoutRepo, sessionStore, cartCubit, tokenCubit);
  });

  tearDown(() async {
    await cubit.close();
    await cartCubit.close();
    await tokenCubit.close();
  });

  test('saveAddress fails when GPS coordinates missing', () async {
    await cubit.saveAddress(
      recipientName: 'أحمد',
      phone: '+963900000000',
      addressLabel: 'دمشق',
    );

    expect(cubit.state, isA<CheckoutFailureState>());
    expect(
      (cubit.state as CheckoutFailureState).message,
      contains('الخريطة'),
    );
  });

  test('selectPaymentMethod rejects Paymera redirect method', () async {
    await seedDraft(
      const CheckoutDraft(latitude: 33.5, longitude: 36.3),
    );

    await cubit.loadPaymentMethods('payment-methods');
    await cubit.selectPaymentMethod(providerCode: 'PAYMERA');

    expect(cubit.state, isA<CheckoutFailureState>());
    expect(
      (cubit.state as CheckoutFailureState).message,
      contains('غير متاحة'),
    );
  });

  test('validateDiscount accepts 10OFF and rejects invalid code inline', () async {
    await seedDraft(
      const CheckoutDraft(
        latitude: 33.5,
        longitude: 36.3,
        shippingQuote: ShippingCostResponse(
          shippingCostSyp: 25000,
          providerCode: 'LOCAL',
          providerName: 'Local',
          estimatedDeliveryHours: 24,
        ),
      ),
    );

    await cartCubit.addItem(
      variantId: 'v1',
      productTitle: 'منتج',
      quantity: 1,
      unitPrice: 100000,
    );

    await cubit.validateDiscount(code: 'INVALID');
    expect(cubit.state, isA<CheckoutLoaded>());
    expect(
      (cubit.state as CheckoutLoaded).draft.discountMessage,
      isNotEmpty,
    );

    await cubit.validateDiscount(code: '10OFF');
    expect(cubit.state, isA<CheckoutLoaded>());
    final loaded = cubit.state as CheckoutLoaded;
    expect(loaded.draft.discountResult, isNotNull);
    expect(loaded.draft.discountMessage, contains('تم تطبيق'));
  });

  test('placeOrder clears cart and keeps lastOrder on success', () async {
    await cartCubit.addItem(
      variantId: 'var-001',
      productTitle: 'منتج',
      quantity: 1,
      unitPrice: 50000,
    );

    await seedDraft(
      CheckoutDraft(
        latitude: 33.5138,
        longitude: 36.2765,
        shippingAddress: const ShippingAddress(
          latitude: 33.5138,
          longitude: 36.2765,
          recipientName: 'أحمد',
          phone: '+963944111222',
        ),
        paymentMethod: 'COD',
        guestEmail: 'guest@example.com',
        checkoutToken: 'token-place-1',
      ),
    );

    await cubit.placeOrder();

    expect(cubit.state, isA<CheckoutLoaded>());
    final draft = (cubit.state as CheckoutLoaded).draft;
    expect(draft.lastOrder, isNotNull);
    expect(draft.paymentMethod, isNull);
    expect(cartCubit.state, isA<CartLoaded>());
    expect((cartCubit.state as CartLoaded).cart.isEmpty, isTrue);
  });
}
