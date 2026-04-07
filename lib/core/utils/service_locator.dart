import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:sooq_merchant/config/config_loader.dart';
import 'package:sooq_merchant/core/cubits/shared_preferences_cubit/shared_preferences_cubit.dart';
import 'package:sooq_merchant/core/cubits/token_cubit/token_cubit.dart';
import 'package:sooq_merchant/core/utils/api_service.dart';
import 'package:sooq_merchant/engine/component_renderer/button_renderer.dart';
import 'package:sooq_merchant/engine/component_renderer/component_renderer.dart';
import 'package:sooq_merchant/engine/component_renderer/insights_card_renderer.dart';
import 'package:sooq_merchant/engine/component_renderer/orders_section_renderer.dart';
import 'package:sooq_merchant/engine/component_renderer/stat_card_renderer.dart';
import 'package:sooq_merchant/engine/component_renderer/stats_section_renderer.dart';
import 'package:sooq_merchant/engine/component_renderer/top_bar_renderer.dart';
import 'package:sooq_merchant/engine/component_renderer/text_renderer.dart';
import 'package:sooq_merchant/features/auth/data/repos/auth_repo_impl.dart';
import 'package:sooq_merchant/features/dashboard/data/dashboard_data_provider.dart';
import 'package:sooq_merchant/features/dashboard/data/repos/dashboard_repo.dart';
import 'package:sooq_merchant/features/dashboard/data/repos/dashboard_repo_impl.dart';
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
  getIt.registerLazySingleton<ConfigLoader>(
    () => JsonConfigLoader(assetPath: 'assets/config/dashboard.json'),
  );

  // Dashboard Data Provider
  getIt.registerLazySingleton<DashboardDataProvider>(
    () => MockDashboardDataProvider(),
  );

  // Dashboard Repo
  getIt.registerLazySingleton<DashboardRepo>(
    () => DashboardRepoImpl(getIt<DashboardDataProvider>()),
  );

  // Variant Repository (MVP V2 tree-based UI)
  getIt.registerLazySingleton<VariantRepository>(
    () => AssetVariantRepository(),
  );

  // Component Renderers
  getIt.registerLazySingleton<Map<String, ComponentRenderer>>(
    () => {
      'button': ButtonRenderer(),
      'statCard': StatCardRenderer(),
      'statsSection': StatsSectionRenderer(),
      'insightsCard': InsightsCardRenderer(),
      'ordersSection': OrdersSectionRenderer(),
      'text': TextRenderer(),
      'topBar': TopBarRenderer(),
    },
  );
}
