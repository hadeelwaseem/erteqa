import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:sooq_merchant/core/cubits/token_cubit/token_cubit.dart';
import 'package:sooq_merchant/core/network/auth_token_storage.dart';
import 'package:sooq_merchant/dev/commerce_mock/mock_checkout_repo.dart';
import 'package:sooq_merchant/dev/commerce_mock/mock_commerce_data.dart';
import 'package:sooq_merchant/dev/commerce_mock/mock_order_repo.dart';
import 'package:sooq_merchant/dev/commerce_mock/mock_shipping_repo.dart';
import 'package:sooq_merchant/engine/actions/action_dispatcher.dart';
import 'package:sooq_merchant/engine/form/form_state_store.dart';
import 'package:sooq_merchant/features/commerce/order/presentation/manager/order_cubit/order_cubit.dart';
import 'package:sooq_merchant/features/commerce/order/presentation/manager/order_cubit/order_state.dart';

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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final locator = GetIt.instance;

  setUp(() {
    MockCommerceData.resetForTests();
    if (locator.isRegistered<OrderCubit>()) {
      locator.unregister<OrderCubit>();
    }
    if (locator.isRegistered<TokenCubit>()) {
      locator.unregister<TokenCubit>();
    }
    locator.registerLazySingleton<TokenCubit>(
      () => TokenCubit(_MemoryTokenStorage()),
    );
    locator.registerLazySingleton<OrderCubit>(
      () => OrderCubit(
        MockOrderRepo(),
        MockCheckoutRepo(),
        MockShippingRepo(),
        locator<TokenCubit>(),
      ),
    );
  });

  tearDown(() async {
    if (locator.isRegistered<OrderCubit>()) {
      await locator.unregister<OrderCubit>();
    }
    if (locator.isRegistered<TokenCubit>()) {
      await locator.unregister<TokenCubit>();
    }
  });

  testWidgets('lookupGuest navigates to order detail on success', (
    tester,
  ) async {
    final formState = FormStateStore();
    final orderNumber = MockCommerceData.firstGuestOrderNumber();
    expect(orderNumber, isNotNull);
    formState.updateValue('orderNumber', orderNumber!);
    formState.updateValue('email', MockCommerceData.defaultGuestEmail);

    String? navigatedRoute;

    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) {
            final dispatcher = EngineActionDispatcher(
              context: context,
              formState: formState,
            );
            return Scaffold(
              body: ElevatedButton(
                onPressed: () => dispatcher.dispatch({
                  'type': 'cubitCall',
                  'cubit': 'order',
                  'method': 'lookupGuest',
                  'requireValidForm': true,
                  'formId': 'guest-order-track-form',
                  'params': {
                    'orderNumber': {
                      'source': 'form',
                      'field': 'orderNumber',
                    },
                    'email': {'source': 'form', 'field': 'email'},
                  },
                  'onSuccess': {
                    'type': 'navigate',
                    'route': '/orders/:orderId',
                    'navigation_type': 'push',
                  },
                }),
                child: const Text('submit'),
              ),
            );
          },
        ),
        GoRoute(
          path: '/orders/:orderId',
          builder: (context, state) {
            navigatedRoute = state.uri.toString();
            return const SizedBox.shrink();
          },
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.tap(find.text('submit'));
    await tester.pumpAndSettle();

    expect(navigatedRoute, isNotNull);
    expect(navigatedRoute, contains('/orders/ord-mock'));
  });

  testWidgets('cancelOrder resolves orderId from routeParams', (
    tester,
  ) async {
    await locator<TokenCubit>().storeToken('token');

    final confirmedId = MockCommerceData.firstConfirmedOrderId();
    expect(confirmedId, isNotNull);

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            final dispatcher = EngineActionDispatcher(
              context: context,
              dataContext: {
                'routeParams': {'orderId': confirmedId},
              },
            );
            return ElevatedButton(
              onPressed: () => dispatcher.dispatch({
                'type': 'cubitCall',
                'cubit': 'order',
                'method': 'cancelOrder',
                'params': {
                  'orderId': {
                    'source': 'routeParams',
                    'field': 'orderId',
                  },
                },
              }),
              child: const Text('cancel'),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('cancel'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(locator<OrderCubit>().state, isA<OrderActionSuccess>());
  });
}
