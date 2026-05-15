import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:sooq_merchant/core/cubits/shared_preferences_cubit/shared_preferences_cubit.dart';
import 'package:sooq_merchant/core/cubits/token_cubit/token_cubit.dart';
import 'package:sooq_merchant/core/network/auth_interceptor.dart';
import 'package:sooq_merchant/core/network/auth_token_storage.dart';
import 'package:sooq_merchant/core/utils/api_service.dart';
import 'package:sooq_merchant/features/auth/data/repos/auth_repo.dart';
import 'package:sooq_merchant/features/auth/data/repos/auth_repo_impl.dart';
import 'package:sooq_merchant/features/auth/presentation/manager/auth_cubit/auth_cubit.dart';
import 'package:sooq_merchant/features/product/data/repos/product_repo_impl.dart';
import 'package:sooq_merchant/features/product/presentation/manager/product_cubit/product_cubit.dart';
import 'package:sooq_merchant/features/variantscreen/data/repos/variant_repository.dart';

GetIt getIt = GetIt.instance;

void setupServiceLocator() {
  getIt.registerLazySingleton<TokenCubit>(() => TokenCubit());
  getIt.registerLazySingleton<AuthTokenStorage>(() => const FlutterAuthTokenStorage());
  getIt.registerLazySingleton<AuthInterceptor>(
    () => AuthInterceptor(
      tokenStorage: getIt<AuthTokenStorage>(),
      onAuthLost: () async {
        await getIt<TokenCubit>().deleteSavedToken();
      },
    ),
  );
  getIt.registerLazySingleton<Dio>(() {
    final dio = Dio(
      BaseOptions(
        headers: const {'Accept': 'application/json'},
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 20),
        sendTimeout: const Duration(seconds: 20),
      ),
    );
    dio.interceptors.add(getIt<AuthInterceptor>());
    return dio;
  });
  getIt.registerLazySingleton<ApiService>(() => ApiService(getIt<Dio>()));
  getIt.registerLazySingleton<AuthRepo>(
    () => AuthRepoImpl(getIt<Dio>(), getIt<AuthTokenStorage>()),
  );
  getIt.registerLazySingleton<SharedPreferencesCubit>(
    () => SharedPreferencesCubit(),
  );

  getIt.registerFactory<AuthCubit>(
    () => AuthCubit(getIt<AuthRepo>(), getIt<TokenCubit>()),
  );

  // Product Repository
  getIt.registerLazySingleton<ProductRepoImpl>(
    () => ProductRepoImpl(getIt<Dio>()),
  );

  // Product Cubit (factory - recreate per screen)
  getIt.registerFactory<ProductCubit>(
    () => ProductCubit(getIt<ProductRepoImpl>()),
  );

  // Config Loader
  // getIt.registerLazySingleton<ConfigLoader>(
  //   () => JsonConfigLoader(assetPath: 'assets/config/dashboard.json'),
  // );

  // Variant Repository (MVP V2 tree-based UI)
  getIt.registerLazySingleton<VariantRepository>(
    () => AssetVariantRepository(),
  );

  // // Component Renderers
  // getIt.registerLazySingleton<Map<String, ComponentRenderer>>(
  //   () => {

  //   },
  // );
}
