import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../config/config_background_sync.dart';
import '../core/cubits/shared_preferences_cubit/shared_preferences_cubit.dart';
import '../core/cubits/token_cubit/token_cubit.dart';
import '../core/network/network_config.dart';
import '../core/utils/app_bloc_observer.dart';
import '../core/utils/app_router.dart';
import '../core/utils/service_locator.dart';
import '../engine/config_pipeline_result.dart';
import 'sooq_app.dart';

Future<void> launchSooqMerchantApp(ConfigPipelineResult pipelineResult) async {
  final mobileConfig = pipelineResult.mobileAppConfig;
  final bootstrap = pipelineResult.bootstrap;

  setupServiceLocator(
    networkConfig: NetworkConfig.fromAppConfig(
      apiBaseUrl: bootstrap.apiBaseUrl.isNotEmpty
          ? bootstrap.apiBaseUrl
          : mobileConfig?.apiBaseUrl,
      tenantId: bootstrap.tenantId ?? mobileConfig?.tenantId,
      tenantSlug: bootstrap.tenantSlug ?? mobileConfig?.tenantSlug,
    ),
    mobileAppConfig: mobileConfig,
    pipelineResult: pipelineResult,
  );

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  final tokenCubit = getIt<TokenCubit>();
  final sharedPreferencesCubit = getIt<SharedPreferencesCubit>();

  await sharedPreferencesCubit.setup();
  await tokenCubit.fetchSavedToken();
  await EasyLocalization.ensureInitialized();

  final router = AppRouter.setupRouter(
    tokenCubit: tokenCubit,
    mobileConfig: mobileConfig,
  );

  Bloc.observer = AppBlocObserver();

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('ar', 'AE'), Locale('en', 'US')],
      path: 'assets/translations',
      fallbackLocale: const Locale('ar', 'AE'),
      startLocale: const Locale('ar', 'AE'),
      child: SOOQApp(
        router: router,
        tokenCubit: tokenCubit,
        sharedPreferencesCubit: sharedPreferencesCubit,
        mobileAppConfig: mobileConfig,
      ),
    ),
  );

  ConfigBackgroundSync.scheduleIfNeeded(pipelineResult);
}
