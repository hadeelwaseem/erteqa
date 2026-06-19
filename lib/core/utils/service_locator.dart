import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:sooq_merchant/config/mobile_app_config.dart';
import 'package:sooq_merchant/core/cubits/shared_preferences_cubit/shared_preferences_cubit.dart';
import 'package:sooq_merchant/core/cubits/token_cubit/token_cubit.dart';
import 'package:sooq_merchant/core/network/auth_interceptor.dart';
import 'package:sooq_merchant/core/network/auth_token_storage.dart';
import 'package:sooq_merchant/core/network/network_config.dart';
import 'package:sooq_merchant/core/utils/api_service.dart';
import 'package:sooq_merchant/core/utils/app_logger.dart';
import 'package:sooq_merchant/dev/auth_mock/auth_mock_config.dart';
import 'package:sooq_merchant/dev/auth_mock/mock_auth_repo.dart';
import 'package:sooq_merchant/features/auth/data/repos/auth_repo.dart';
import 'package:sooq_merchant/features/auth/data/repos/auth_repo_impl.dart';
import 'package:sooq_merchant/features/auth/presentation/manager/auth_cubit/auth_cubit.dart';
import 'package:sooq_merchant/features/product/data/repos/product_repo.dart';
import 'package:sooq_merchant/features/product/data/repos/product_repo_impl.dart';
import 'package:sooq_merchant/dev/product_mock/product_mock_config.dart';
import 'package:sooq_merchant/dev/product_mock/mock_product_repo.dart';
import 'package:sooq_merchant/features/product/presentation/manager/category_cubit/category_cubit.dart';
import 'package:sooq_merchant/features/product/presentation/manager/product_autocomplete_cubit/product_autocomplete_cubit.dart';
import 'package:sooq_merchant/features/product/presentation/manager/product_cubit/product_cubit.dart';
import 'package:sooq_merchant/features/product/presentation/manager/product_detail_cubit/product_detail_cubit.dart';
import 'package:sooq_merchant/features/product/presentation/manager/product_search_cubit/product_search_cubit.dart';
import 'package:sooq_merchant/features/commerce/cart/data/datasources/cart_local_storage.dart';
import 'package:sooq_merchant/features/commerce/cart/data/repos/cart_repo.dart';
import 'package:sooq_merchant/features/commerce/cart/data/repos/cart_repo_impl.dart';
import 'package:sooq_merchant/features/commerce/cart/presentation/manager/cart_cubit/cart_cubit.dart';
import 'package:sooq_merchant/features/commerce/wishlist/data/datasources/wishlist_local_storage.dart';
import 'package:sooq_merchant/features/commerce/wishlist/data/repos/wishlist_repo.dart';
import 'package:sooq_merchant/features/commerce/wishlist/data/repos/wishlist_repo_impl.dart';
import 'package:sooq_merchant/features/commerce/wishlist/presentation/manager/wishlist_cubit/wishlist_cubit.dart';
import 'package:sooq_merchant/features/commerce/checkout/data/datasources/checkout_session_store.dart';
import 'package:sooq_merchant/features/commerce/checkout/data/repos/checkout_repo.dart';
import 'package:sooq_merchant/features/commerce/checkout/data/repos/checkout_repo_impl.dart';
import 'package:sooq_merchant/features/commerce/checkout/presentation/manager/checkout_cubit/checkout_cubit.dart';
import 'package:sooq_merchant/features/commerce/order/presentation/manager/order_cubit/order_cubit.dart';
import 'package:sooq_merchant/features/commerce/order/data/repos/order_repo.dart';
import 'package:sooq_merchant/features/commerce/order/data/repos/order_repo_impl.dart';
import 'package:sooq_merchant/features/commerce/shipping/data/repos/shipping_repo.dart';
import 'package:sooq_merchant/features/commerce/shipping/data/repos/shipping_repo_impl.dart';
import 'package:sooq_merchant/dev/commerce_mock/commerce_mock_config.dart';
import 'package:sooq_merchant/dev/commerce_mock/mock_checkout_repo.dart';
import 'package:sooq_merchant/dev/commerce_mock/mock_order_repo.dart';
import 'package:sooq_merchant/dev/commerce_mock/mock_shipping_repo.dart';
import 'package:sooq_merchant/engine/config_pipeline_result.dart';
import 'package:sooq_merchant/features/variantscreen/data/repos/json_variant_repository.dart';
import 'package:sooq_merchant/features/variantscreen/data/repos/variant_repository.dart';

GetIt getIt = GetIt.instance;

MobileAppConfig? _registeredMobileAppConfig;
ConfigPipelineResult? _registeredPipelineResult;

MobileAppConfig? get registeredMobileAppConfig => _registeredMobileAppConfig;
ConfigPipelineResult? get registeredPipelineResult => _registeredPipelineResult;

void setupServiceLocator({
  NetworkConfig? networkConfig,
  MobileAppConfig? mobileAppConfig,
  ConfigPipelineResult? pipelineResult,
}) {
  _resetIfRegistered<NetworkConfig>();
  _resetIfRegistered<AuthTokenStorage>();
  _resetIfRegistered<Dio>();
  _resetIfRegistered<ApiService>();
  _resetIfRegistered<AuthRepo>();
  _resetIfRegistered<AuthCubit>();
  _resetIfRegistered<TokenCubit>();
  _resetIfRegistered<SharedPreferencesCubit>();
  _resetIfRegistered<ProductRepo>();
  _resetIfRegistered<ProductCubit>();
  _resetIfRegistered<ProductSearchCubit>();
  _resetIfRegistered<ProductAutocompleteCubit>();
  _resetIfRegistered<ProductDetailCubit>();
  _resetIfRegistered<CategoryCubit>();
  _resetIfRegistered<VariantRepository>();
  _resetIfRegistered<CartRepo>();
  _resetIfRegistered<CartCubit>();
  _resetIfRegistered<WishlistRepo>();
  _resetIfRegistered<WishlistCubit>();
  _resetIfRegistered<CheckoutRepo>();
  _resetIfRegistered<OrderRepo>();
  _resetIfRegistered<ShippingRepo>();

  _registeredMobileAppConfig = mobileAppConfig;
  _registeredPipelineResult = pipelineResult;

  final resolvedNetworkConfig =
      networkConfig ??
      NetworkConfig.fromAppConfig(
        apiBaseUrl: mobileAppConfig?.apiBaseUrl,
        tenantId: mobileAppConfig?.tenantId,
        tenantSlug: mobileAppConfig?.tenantSlug,
      );

  getIt.registerLazySingleton<NetworkConfig>(() => resolvedNetworkConfig);
  getIt.registerLazySingleton<AuthTokenStorage>(
    () => const FlutterAuthTokenStorage(),
  );
  getIt.registerLazySingleton<TokenCubit>(
    () => TokenCubit(getIt<AuthTokenStorage>()),
  );
  getIt.registerLazySingleton<SharedPreferencesCubit>(
    () => SharedPreferencesCubit(),
  );

  getIt.registerLazySingleton<Dio>(() {
    final dio = Dio(
      BaseOptions(
        baseUrl: getIt<NetworkConfig>().baseUrl,
        headers: const {'Accept': 'application/json'},
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 20),
        sendTimeout: const Duration(seconds: 20),
      ),
    );
    dio.interceptors.add(
      AuthInterceptor(
        mainDio: dio,
        tokenStorage: getIt<AuthTokenStorage>(),
        onAuthLost: () async {
          AppLogger.auth(
            'session lost — clearing tokens and returning to login',
          );
          await getIt<AuthCubit>().logout();
        },
      ),
    );
    return dio;
  });

  getIt.registerLazySingleton<ApiService>(() => ApiService(getIt<Dio>()));
  getIt.registerLazySingleton<AuthRepo>(() {
    if (AuthMockConfig.enabled) {
      AppLogger.auth(
        'AuthMockConfig.enabled=true — using MockAuthRepo (no OTP HTTP)',
      );
      return MockAuthRepo(getIt<AuthTokenStorage>());
    }
    return AuthRepoImpl(getIt<Dio>(), getIt<AuthTokenStorage>());
  });
  getIt.registerLazySingleton<AuthCubit>(
    () => AuthCubit(getIt<AuthRepo>(), getIt<TokenCubit>()),
  );

  getIt.registerLazySingleton<ProductRepo>(() {
    if (ProductMockConfig.enabled) {
      AppLogger.network(
        'ProductMockConfig.enabled=true — using MockProductRepo (no HTTP)',
      );
      return MockProductRepo();
    }
    return ProductRepoImpl(getIt<Dio>());
  });

  getIt.registerFactory<ProductCubit>(() => ProductCubit(getIt<ProductRepo>()));

  getIt.registerFactory<ProductSearchCubit>(
    () => ProductSearchCubit(getIt<ProductRepo>()),
  );

  getIt.registerFactory<ProductAutocompleteCubit>(
    () => ProductAutocompleteCubit(getIt<ProductRepo>()),
  );

  getIt.registerFactory<ProductDetailCubit>(
    () => ProductDetailCubit(getIt<ProductRepo>()),
  );

  getIt.registerFactory<CategoryCubit>(
    () => CategoryCubit(getIt<ProductRepo>()),
  );

  getIt.registerLazySingleton<VariantRepository>(() {
    final result = _registeredPipelineResult;
    if (result?.rawConfigJson != null) {
      return JsonVariantRepository(result!.rawConfigJson!);
    }
    return AssetVariantRepository();
  });

  getIt.registerLazySingleton<CartRepo>(
    () => CartRepoImpl(CartLocalStorage()),
  );
  getIt.registerLazySingleton<CartCubit>(
    () => CartCubit(getIt<CartRepo>())..loadCart(),
  );

  getIt.registerLazySingleton<WishlistRepo>(
    () => WishlistRepoImpl(WishlistLocalStorage()),
  );
  getIt.registerLazySingleton<WishlistCubit>(
    () => WishlistCubit(getIt<WishlistRepo>())..load(),
  );

  getIt.registerLazySingleton<CheckoutSessionStore>(
    () => CheckoutSessionStore(),
  );

  getIt.registerLazySingleton<CheckoutRepo>(() {
    if (CommerceMockConfig.enabled) {
      AppLogger.network(
        'CommerceMockConfig.enabled=true — using MockCheckoutRepo (no HTTP)',
      );
      return MockCheckoutRepo();
    }
    return CheckoutRepoImpl(getIt<Dio>());
  });

  getIt.registerLazySingleton<CheckoutCubit>(
    () => CheckoutCubit(
      getIt<CheckoutRepo>(),
      getIt<CheckoutSessionStore>(),
      getIt<CartCubit>(),
      getIt<TokenCubit>(),
    )..loadDraft(),
  );

  getIt.registerLazySingleton<OrderRepo>(() {
    if (CommerceMockConfig.enabled) {
      AppLogger.network(
        'CommerceMockConfig.enabled=true — using MockOrderRepo (no HTTP)',
      );
      return MockOrderRepo();
    }
    return OrderRepoImpl(getIt<Dio>());
  });

  getIt.registerLazySingleton<ShippingRepo>(() {
    if (CommerceMockConfig.enabled) {
      AppLogger.network(
        'CommerceMockConfig.enabled=true — using MockShippingRepo (no HTTP)',
      );
      return MockShippingRepo();
    }
    return ShippingRepoImpl(getIt<Dio>());
  });

  getIt.registerLazySingleton<OrderCubit>(
    () => OrderCubit(
      getIt<OrderRepo>(),
      getIt<CheckoutRepo>(),
      getIt<ShippingRepo>(),
      getIt<TokenCubit>(),
    ),
  );
}

void _resetIfRegistered<T extends Object>() {
  if (getIt.isRegistered<T>()) {
    getIt.unregister<T>();
  }
}
