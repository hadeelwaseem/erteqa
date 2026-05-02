import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sooq_merchant/core/utils/constants.dart';
import 'package:sooq_merchant/core/cubits/shared_preferences_cubit/shared_preferences_cubit.dart';
import 'package:sooq_merchant/core/cubits/token_cubit/token_cubit.dart';
import 'package:sooq_merchant/core/utils/app_bloc_observer.dart';
import 'package:sooq_merchant/core/utils/app_router.dart';
import 'package:sooq_merchant/core/utils/service_locator.dart';
import 'package:sooq_merchant/core/utils/size_config.dart';
import 'package:sooq_merchant/engine/app_config_loader.dart';

/// The JSON file that drives the app.
/// Change this to switch to a different config at any time.
const _kActiveConfig = 'mobile_component_flow_demo';

void main() async {
  // 1. Initialize Flutter bindings
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Setup Dependency Injection
  setupServiceLocator();

  // 3. System UI
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: primaryColor,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  final tokenCubit = getIt<TokenCubit>();
  final sharedPreferencesCubit = getIt<SharedPreferencesCubit>();

  // 4. Startup init — void-returning calls run before the parallel wait
  await sharedPreferencesCubit.setup();
  await tokenCubit.fetchSavedToken();
  await EasyLocalization.ensureInitialized();

  // Load mobile app config (async, non-void — may return null on failure)
  final mobileConfig = await AppConfigLoader.load(_kActiveConfig);

  // 5. Build router from config (tab shell) or fallback
  final router = AppRouter.setupRouter(
    tokenCubit.state,
    mobileConfig: mobileConfig,
  );

  // 6. Bloc observer
  Bloc.observer = AppBlocObserver();

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('ar', 'AE'), Locale('en', 'US')],
      path: 'assets/translations',
      fallbackLocale: const Locale('ar', 'AE'),
      startLocale: const Locale('en', 'US'),
      child: SOOQApp(
        router: router,
        tokenCubit: tokenCubit,
        sharedPreferencesCubit: sharedPreferencesCubit,
      ),
    ),
  );
}

class SOOQApp extends StatelessWidget {
  final GoRouter router;
  final TokenCubit tokenCubit;
  final SharedPreferencesCubit sharedPreferencesCubit;

  const SOOQApp({
    super.key,
    required this.router,
    required this.tokenCubit,
    required this.sharedPreferencesCubit,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: tokenCubit),
        BlocProvider.value(value: sharedPreferencesCubit),
      ],
      child: Builder(
        builder: (context) {
          SizeConfig.init(context);
          return MaterialApp.router(
            theme: ThemeData(
              useMaterial3: false,
              fontFamily: 'inter',
              scaffoldBackgroundColor: const Color(0xFFF4F6FA),
            ),
            localizationsDelegates: context.localizationDelegates,
            supportedLocales: context.supportedLocales,
            locale: context.locale,
            routerConfig: router,
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
