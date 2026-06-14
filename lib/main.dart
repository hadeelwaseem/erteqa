import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sooq_merchant/core/network/network_config.dart';
import 'package:sooq_merchant/core/cubits/shared_preferences_cubit/shared_preferences_cubit.dart';
import 'package:sooq_merchant/core/cubits/token_cubit/token_cubit.dart';
import 'package:sooq_merchant/features/commerce/cart/presentation/manager/cart_cubit/cart_cubit.dart';
import 'package:sooq_merchant/features/commerce/wishlist/presentation/manager/wishlist_cubit/wishlist_cubit.dart';
import 'package:sooq_merchant/features/commerce/checkout/presentation/manager/checkout_cubit/checkout_cubit.dart';
import 'package:sooq_merchant/features/commerce/order/presentation/manager/order_cubit/order_cubit.dart';
import 'package:sooq_merchant/core/utils/app_logger.dart';
import 'package:sooq_merchant/core/utils/app_bloc_observer.dart';
import 'package:sooq_merchant/dev/auth_mock/auth_mock_config.dart';
import 'package:sooq_merchant/core/utils/app_router.dart';
import 'package:sooq_merchant/core/utils/service_locator.dart';
import 'package:sooq_merchant/core/utils/size_config.dart';
import 'package:sooq_merchant/config/mobile_app_config.dart';
import 'package:sooq_merchant/engine/config_pipeline.dart';
import 'package:sooq_merchant/engine/theme/engine_theme.dart';

void main() async {
  // 1. Initialize Flutter bindings
  WidgetsFlutterBinding.ensureInitialized();

  assert(() {
    debugPaintBaselinesEnabled = false;
    debugPaintSizeEnabled = false;
    debugPaintLayerBordersEnabled = false;
    return true;
  }());

  // 2. Load bootstrap + full config before DI (base URL + tenant)
  final pipelineResult = await ConfigPipeline.initialize();
  final mobileConfig = pipelineResult.mobileAppConfig;
  final bootstrap = pipelineResult.bootstrap;

  // 3. Setup Dependency Injection
  if (AuthMockConfig.enabled) {
    AppLogger.auth(
      'TEMPORARY: Auth mock enabled — see lib/dev/auth_mock/README.md',
    );
  }
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

  // 4. System UI
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  final tokenCubit = getIt<TokenCubit>();
  final sharedPreferencesCubit = getIt<SharedPreferencesCubit>();

  // 5. Startup init
  await sharedPreferencesCubit.setup();
  await tokenCubit.fetchSavedToken();
  await EasyLocalization.ensureInitialized();

  // 6. Build router from config (tab shell) or fallback
  final router = AppRouter.setupRouter(
    tokenCubit: tokenCubit,
    mobileConfig: mobileConfig,
  );

  // 7. Bloc observer
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
}

class SOOQApp extends StatelessWidget {
  final GoRouter router;
  final TokenCubit tokenCubit;
  final SharedPreferencesCubit sharedPreferencesCubit;
  final MobileAppConfig? mobileAppConfig;

  const SOOQApp({
    super.key,
    required this.router,
    required this.tokenCubit,
    required this.sharedPreferencesCubit,
    this.mobileAppConfig,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: tokenCubit),
        BlocProvider.value(value: sharedPreferencesCubit),
        BlocProvider.value(value: getIt<CartCubit>()),
        BlocProvider.value(value: getIt<WishlistCubit>()),
        BlocProvider.value(value: getIt<CheckoutCubit>()),
        BlocProvider.value(value: getIt<OrderCubit>()),
      ],
      child: Builder(
        builder: (context) {
          SizeConfig.init(context);
          return MaterialApp.router(
            theme: mobileAppConfig != null
                ? EngineTheme.toThemeData(mobileAppConfig!.theme)
                : ThemeData(useMaterial3: true),
            localizationsDelegates: context.localizationDelegates,
            supportedLocales: context.supportedLocales,
            locale: context.locale,
            builder: (context, child) {
              final isRtl = context.locale.languageCode == 'ar';
              return Directionality(
                textDirection: isRtl
                    ? ui.TextDirection.rtl
                    : ui.TextDirection.ltr,
                child: child ?? const SizedBox.shrink(),
              );
            },
            routerConfig: router,
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
