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

void main() async {
  // 1. تهيئة الـ Bindings
  WidgetsFlutterBinding.ensureInitialized();

  // 2. إعداد Service Locator
  setupServiceLocator();

  // 3. إعدادات الواجهة
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: primaryColor, // Status bar color
      statusBarIconBrightness: Brightness.light, // Status bar icons' color
    ),
  );

  final tokenCubit = getIt<TokenCubit>();
  final sharedPreferencesCubit = getIt<SharedPreferencesCubit>();

  await Future.wait([
    sharedPreferencesCubit.setup(),
    //  sharedPreferencesCubit.deleteAll(),
    //  tokenCubit.deleteSavedToken(),
    tokenCubit.fetchSavedToken(),
    EasyLocalization.ensureInitialized(),
  ]);

  // 6. إعداد الـ Router بعد التأكد من وجود التوكن
  final router = AppRouter.setupRouter(tokenCubit.state);

  // 7. إعداد مراقب الـ Bloc
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
              scaffoldBackgroundColor: const Color(0xfff4f6fa),
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
