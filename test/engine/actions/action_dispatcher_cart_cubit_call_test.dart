import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:sooq_merchant/core/errors/failures.dart';
import 'package:sooq_merchant/core/feedback/app_messenger.dart';
import 'package:sooq_merchant/engine/actions/action_dispatcher.dart';
import 'package:sooq_merchant/engine/form/form_state_store.dart';
import 'package:sooq_merchant/features/commerce/cart/data/repos/cart_repo.dart';
import 'package:sooq_merchant/features/commerce/cart/presentation/manager/cart_cubit/cart_cubit.dart';
import 'package:sooq_merchant/features/commerce/cart/presentation/manager/cart_cubit/cart_state.dart';
import 'package:sooq_merchant/features/commerce/data/models/cart.dart';
import 'package:sooq_merchant/features/commerce/data/models/cart_line.dart';

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

void main() {
  final locator = GetIt.instance;
  late _MemoryCartRepo repo;

  setUp(() {
    repo = _MemoryCartRepo();
    if (locator.isRegistered<CartCubit>()) {
      locator.unregister<CartCubit>();
    }
    locator.registerLazySingleton<CartCubit>(() => CartCubit(repo));
  });

  tearDown(() {
    AppMessenger.dismiss();
    if (locator.isRegistered<CartCubit>()) {
      locator.unregister<CartCubit>();
    }
  });

  testWidgets('cart addItem resolves form and datacontext params', (tester) async {
    final formState = FormStateStore();
    formState.updateValue('selectedVariantId', 'var-abc');

    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) {
            final dispatcher = EngineActionDispatcher(
              context: context,
              formState: formState,
              dataContext: {
                'requests': {
                  'product-detail': {
                    'data': {
                      'name': 'حذاء رياضي',
                      'primaryImageUrl': 'https://example.com/p.png',
                    },
                  },
                },
              },
            );
            return Scaffold(
              body: ElevatedButton(
                onPressed: () => dispatcher.dispatch({
                  'type': 'cubitCall',
                  'cubit': 'cart',
                  'method': 'addItem',
                  'params': {
                    'variantId': {
                      'source': 'form',
                      'field': 'selectedVariantId',
                    },
                    'quantity': {'value': 1},
                    'productTitle': {
                      'source': 'datacontext',
                      'field': 'requests.product-detail.data.name',
                    },
                    'thumbnailUrl': {
                      'source': 'datacontext',
                      'field': 'requests.product-detail.data.primaryImageUrl',
                    },
                    'unitPrice': {'value': 12000},
                  },
                }),
                child: const Text('Add'),
              ),
            );
          },
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();

    final state = locator<CartCubit>().state;
    expect(state, isA<CartActionSuccess>());
    final cart = (state as CartActionSuccess).cart;
    expect(cart.items.single.variantId, 'var-abc');
    expect(cart.items.single.productTitle, 'حذاء رياضي');
    expect(cart.items.single.thumbnailUrl, 'https://example.com/p.png');
  });

  testWidgets('cart assertNotEmpty blocks navigate when empty', (tester) async {
    late GoRouter router;
    router = GoRouter(
      initialLocation: '/cart',
      routes: [
        GoRoute(
          path: '/cart',
          builder: (context, state) {
            final dispatcher = EngineActionDispatcher(context: context);
            return Scaffold(
              body: ElevatedButton(
                onPressed: () => dispatcher.dispatch({
                  'type': 'cubitCall',
                  'cubit': 'cart',
                  'method': 'assertNotEmpty',
                  'onSuccess': {
                    'type': 'navigate',
                    'route': '/checkout',
                    'navigation_type': 'push',
                  },
                }),
                child: const Text('Checkout'),
              ),
            );
          },
        ),
        GoRoute(
          path: '/checkout',
          builder: (context, state) => const Scaffold(body: Text('Checkout')),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.tap(find.text('Checkout'));
    await tester.pumpAndSettle();

    expect(router.state.uri.path, '/cart');
    expect(locator<CartCubit>().state, isA<CartFailureState>());
  });

  testWidgets('cart updateQuantity resolves item.variantId', (tester) async {
    await repo.save(
      const Cart(
        items: [
          CartLine(
            variantId: 'line-1',
            quantity: 2,
            productTitle: 'منتج',
            unitPrice: 1000,
          ),
        ],
      ),
    );
    locator<CartCubit>().emit(
      CartLoaded((await repo.load()).getOrElse(() => const Cart())),
    );

    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) {
            final dispatcher = EngineActionDispatcher(
              context: context,
              dataContext: {
                'item': {
                  'variantId': 'line-1',
                },
              },
            );
            return Scaffold(
              body: ElevatedButton(
                onPressed: () => dispatcher.dispatch({
                  'type': 'cubitCall',
                  'cubit': 'cart',
                  'method': 'updateQuantity',
                  'params': {
                    'variantId': {'source': 'item', 'field': 'variantId'},
                    'delta': {'value': -1},
                  },
                }),
                child: const Text('Minus'),
              ),
            );
          },
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.tap(find.text('Minus'));
    await tester.pumpAndSettle();

    final cart = (locator<CartCubit>().state as CartLoaded).cart;
    expect(cart.items.single.quantity, 1);
  });
}
