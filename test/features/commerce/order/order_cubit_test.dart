import 'package:flutter_test/flutter_test.dart';
import 'package:sooq_merchant/core/cubits/token_cubit/token_cubit.dart';
import 'package:sooq_merchant/core/network/auth_token_storage.dart';
import 'package:sooq_merchant/dev/commerce_mock/mock_checkout_repo.dart';
import 'package:sooq_merchant/dev/commerce_mock/mock_commerce_data.dart';
import 'package:sooq_merchant/dev/commerce_mock/mock_order_repo.dart';
import 'package:sooq_merchant/dev/commerce_mock/mock_shipping_repo.dart';
import 'package:sooq_merchant/features/commerce/order/presentation/manager/order_cubit/order_cubit.dart';
import 'package:sooq_merchant/features/commerce/order/presentation/manager/order_cubit/order_state.dart';

class _MemoryTokenStorage implements AuthTokenStorage {
  String? _token;

  void setToken(String? token) => _token = token;

  @override
  Future<void> clearTokens() async => _token = null;

  @override
  Future<String?> readAccessToken() async => _token;

  @override
  Future<DateTime?> readExpiresAt() async => null;

  @override
  Future<String?> readRefreshToken() async => null;

  @override
  Future<String?> readTenantId() async => null;

  @override
  Future<AuthTokenBundle> readTokenBundle() async =>
      AuthTokenBundle(accessToken: _token);

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    DateTime? expiresAt,
    String? tenantId,
  }) async {
    _token = accessToken;
  }
}

void main() {
  late MockOrderRepo orderRepo;
  late MockCheckoutRepo checkoutRepo;
  late MockShippingRepo shippingRepo;
  late _MemoryTokenStorage tokenStorage;
  late TokenCubit tokenCubit;
  late OrderCubit cubit;

  setUp(() {
    MockCommerceData.resetForTests();
    orderRepo = MockOrderRepo();
    checkoutRepo = MockCheckoutRepo();
    shippingRepo = MockShippingRepo();
    tokenStorage = _MemoryTokenStorage();
    tokenCubit = TokenCubit(tokenStorage);
    cubit = OrderCubit(orderRepo, checkoutRepo, shippingRepo, tokenCubit);
  });

  tearDown(() async {
    await cubit.close();
    await tokenCubit.close();
  });

  test('loadOrders emits list success with meta', () async {
    await tokenCubit.storeToken('token');

    await cubit.loadOrders('my-orders', page: 0, size: 20);

    final state = cubit.state;
    expect(state, isA<OrderListSuccess>());
    final success = state as OrderListSuccess;
    expect(success.requestKey, 'my-orders');
    expect(success.response.data, isNotEmpty);
    expect(success.response.meta.page, 0);
  });

  test('lookupGuest 404 sets inline error without failure state toast path', () async {
    await cubit.lookupGuest(
      orderNumber: 'INVALID',
      email: MockCommerceData.defaultGuestEmail,
    );

    expect(cubit.guestLookupError, isNotNull);
    expect(cubit.lastLookupOrderId, isNull);
    expect(cubit.state, isA<OrderGuestLookupUpdated>());
  });

  test('lookupGuest success caches order for guest detail', () async {
    final orderNumber = MockCommerceData.firstGuestOrderNumber();
    expect(orderNumber, isNotNull);

    await cubit.lookupGuest(
      orderNumber: orderNumber!,
      email: MockCommerceData.defaultGuestEmail,
    );

    expect(cubit.lastLookupOrderId, isNotNull);
    expect(cubit.guestLookupError, isNull);

    await cubit.loadOrderDetail(
      requestKey: 'order-detail',
      orderId: cubit.lastLookupOrderId!,
    );

    expect(cubit.state, isA<OrderDetailSuccess>());
  });

  test('loadShipmentTrack maps missing shipment to empty success', () async {
    const pendingOrderId = 'ord-mock-1001';

    await cubit.loadShipmentTrack(
      requestKey: 'shipment-track',
      orderId: pendingOrderId,
    );

    expect(cubit.state, isA<OrderShipmentEmpty>());
  });

  test('cancelOrder on delivered order emits failure', () async {
    await tokenCubit.storeToken('token');
    final deliveredId = MockCommerceData.firstDeliveredOrderId();
    expect(deliveredId, isNotNull);

    await cubit.cancelOrder(orderId: deliveredId!);

    expect(cubit.state, isA<OrderFailureState>());
  });

  test('cancelOrder on confirmed order emits action success', () async {
    await tokenCubit.storeToken('token');
    final confirmedId = MockCommerceData.firstConfirmedOrderId();
    expect(confirmedId, isNotNull);

    await cubit.cancelOrder(orderId: confirmedId!);

    expect(cubit.state, isA<OrderActionSuccess>());
  });
}
