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
import 'package:sooq_merchant/features/auth/data/repos/auth_repo.dart';
import 'package:sooq_merchant/features/auth/data/repos/auth_repo_impl.dart';
import 'package:sooq_merchant/features/auth/presentation/manager/auth_cubit/auth_cubit.dart';
import 'package:sooq_merchant/features/product/data/repos/product_repo_impl.dart';
import 'package:sooq_merchant/features/product/presentation/manager/product_cubit/product_cubit.dart';
import 'package:sooq_merchant/features/variantscreen/data/repos/variant_repository.dart';

GetIt getIt = GetIt.instance;

MobileAppConfig? _registeredMobileAppConfig;

MobileAppConfig? get registeredMobileAppConfig => _registeredMobileAppConfig;

void setupServiceLocator({
  NetworkConfig? networkConfig,
  MobileAppConfig? mobileAppConfig,
}) {
  _resetIfRegistered<NetworkConfig>();
  _resetIfRegistered<AuthTokenStorage>();
  _resetIfRegistered<Dio>();
  _resetIfRegistered<ApiService>();
  _resetIfRegistered<AuthRepo>();
  _resetIfRegistered<AuthCubit>();
  _resetIfRegistered<TokenCubit>();
  _resetIfRegistered<SharedPreferencesCubit>();
  _resetIfRegistered<ProductRepoImpl>();
  _resetIfRegistered<ProductCubit>();
  _resetIfRegistered<VariantRepository>();

  _registeredMobileAppConfig = mobileAppConfig;

  final resolvedNetworkConfig = networkConfig ??
      NetworkConfig.fromAppConfig(
        apiBaseUrl: mobileAppConfig?.apiBaseUrl,
        tenantSlug: mobileAppConfig?.tenantSlug,
      );

  getIt.registerLazySingleton<NetworkConfig>(() => resolvedNetworkConfig);
  getIt.registerLazySingleton<AuthTokenStorage>(() => const FlutterAuthTokenStorage());
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
          AppLogger.auth('session lost — clearing tokens and returning to login');
          await getIt<AuthCubit>().logout();
        },
      ),
    );
    return dio;
  });

  getIt.registerLazySingleton<ApiService>(() => ApiService(getIt<Dio>()));
  getIt.registerLazySingleton<AuthRepo>(
    () => AuthRepoImpl(getIt<Dio>(), getIt<AuthTokenStorage>()),
  );
  getIt.registerLazySingleton<AuthCubit>(
    () => AuthCubit(getIt<AuthRepo>(), getIt<TokenCubit>()),
  );

  getIt.registerLazySingleton<ProductRepoImpl>(
    () => ProductRepoImpl(getIt<Dio>()),
  );

  getIt.registerFactory<ProductCubit>(
    () => ProductCubit(getIt<ProductRepoImpl>()),
  );

  getIt.registerLazySingleton<VariantRepository>(
    () => AssetVariantRepository(),
  );
}

void _resetIfRegistered<T extends Object>() {
  if (getIt.isRegistered<T>()) {
    getIt.unregister<T>();
  }
}
