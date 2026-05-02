import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:sooq_merchant/core/cubits/shared_preferences_cubit/shared_preferences_cubit.dart';
import 'package:sooq_merchant/core/cubits/token_cubit/token_cubit.dart';
import 'package:sooq_merchant/core/utils/api_service.dart';
import 'package:sooq_merchant/features/auth/data/repos/auth_repo_impl.dart';
import 'package:sooq_merchant/features/variantscreen/data/repos/variant_repository.dart';

GetIt getIt = GetIt.instance;

void setupServiceLocator() {
  getIt.registerLazySingleton<Dio>(() => Dio());
  getIt.registerLazySingleton<ApiService>(() => ApiService(getIt<Dio>()));
  getIt.registerLazySingleton<AuthRepoImpl>(
    () => AuthRepoImpl(getIt<ApiService>()),
  );

  getIt.registerLazySingleton<TokenCubit>(() => TokenCubit());
  getIt.registerLazySingleton<SharedPreferencesCubit>(
    () => SharedPreferencesCubit(),
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
