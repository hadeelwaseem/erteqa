import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:sooq_merchant/constants.dart';

import 'package:sooq_merchant/core/cubits/hydrated_cubit_instance.dart';
import 'package:sooq_merchant/core/cubits/shared_preferences_cubit/shared_preferences_cubit.dart';
import 'package:sooq_merchant/core/cubits/token_cubit/token_cubit.dart';
import 'package:sooq_merchant/core/utils/app_bloc_observer.dart';
import 'package:sooq_merchant/core/utils/app_router.dart';
import 'package:sooq_merchant/core/utils/service_locator.dart';
import 'package:sooq_merchant/core/utils/size_config.dart';
import 'package:sooq_merchant/features/auth/data/models/user_model/user.dart';

import 'core/cubits/theme_cubit/theme_cubit.dart';
import 'theme/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  setupServiceLocator();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: kAppColor, // Status bar color
      statusBarIconBrightness: Brightness.light, // Status bar icons' color
    ),
  );

  final tokenCubit = getIt<TokenCubit>();
  // final gradeCubit = getIt<GradeCubit>();
  final sharedPreferencesCubit = getIt<SharedPreferencesCubit>();
  // final deviceTokenCubit = getIt<DeviceTokenCubit>();
  // final directoryCubit = getIt<DirectoryCubit>();
  // final hydratedCubit = getIt<HydratedCubitInstance>();
  await Hive.initFlutter();
  // Hive.registerAdapter(UserAdapter());
  // Hive.registerAdapter(VideoAdapter());
  // Hive.registerAdapter(FileStateAdapter());

  await Future.wait([
    // Hive.openBox<User>(kUser),
    // Hive.openBox<Video>(kVideo),
    // Hive.openBox<FileState>(kFileState),
    sharedPreferencesCubit.setup(),
    //  sharedPreferencesCubit.deleteAll(),
    //  tokenCubit.deleteSavedToken(),
    tokenCubit.fetchSavedToken(),
    // directoryCubit.fetchDocsDir(),
    // deviceTokenCubit.fetchDeviceToken(),
    EasyLocalization.ensureInitialized(),
  ]);
  // await hydratedCubit.setup();
  final router = AppRouter.setupRouter(
    tokenCubit.state,
    // deviceTokenCubit.state,
    sharedPreferencesCubit.getGrade(),
  );
  // Bloc.observer = AppBlocObserver();
  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('ar', 'AE'), Locale('en', 'US')],
      path: 'assets/translations',
      fallbackLocale: const Locale('ar', 'AE'),
      startLocale: const Locale('en', 'US'),
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (context) => getIt<SharedPreferencesCubit>()),

          //   BlocProvider(create: (context) => getIt<DirectoryCubit>(),),
          // BlocProvider(
          //   create: (context) => getIt<DownloadsCubit>(),
          // ),
          // BlocProvider(
          //     create: (context) => SearchSubjectsCubit(
          //           getIt<HomeRepoImpl>(),
          //         )),
          // BlocProvider(
          //     create: (context) => FavoriteCubit(
          //           getIt<HomeRepoImpl>(),
          //         )),
          // BlocProvider(
          //     create: (context) => FetchFavoriteCubit(
          //           getIt<HomeRepoImpl>(),
          //         )),
          // BlocProvider(
          //     create: (context) => FetchBookMarkCubit(
          //           getIt<HomeRepoImpl>(),
          //         )),
          // BlocProvider(
          //     create: (context) => PostBookMarkcubit(
          //           getIt<HomeRepoImpl>(),
          //         )),

          // BlocProvider(
          //     create: (context) => FetchTeacherProfileCubit(
          //           getIt<SubjectRepoImpl>(),
          //         )),
          // BlocProvider(
          //   create: (context) => ThemeCubit(), //هنا اضافة ال theme cubit
          // ),
        ],
        child: LMSApp(router: router),
      ),
    ),
  );
}

class LMSApp extends StatelessWidget {
  final GoRouter router;
  const LMSApp({super.key, required this.router});

  @override
  Widget build(BuildContext context) {
    // SizeConfig.init(context);
    return BlocBuilder<ThemeCubit, ThemeMode>(
      builder: (context, themeMode) {
        return MaterialApp.router(
          // theme: ThemeData(
          //   useMaterial3: false,
          //   fontFamily: 'inter',
          // ).copyWith(
          //     appBarTheme: const AppBarTheme(
          //       color: kAppColor,
          //     ),
          //     // inputDecorationTheme: InputDecorationTheme(
          //     //   focusedBorder: OutlineInputBorder(
          //     //     borderSide: const BorderSide(color: Color.fromARGB(255, 0, 0, 0)),
          //     //     borderRadius: BorderRadius.circular(20),
          //     //   ),
          //     //   enabledBorder: OutlineInputBorder(
          //     //     borderSide: const BorderSide(color: Color.fromARGB(255, 0, 0, 0)),
          //     //     borderRadius: BorderRadius.circular(100),
          //     //   ),
          //     //   disabledBorder: OutlineInputBorder(
          //     //     borderRadius: BorderRadius.circular(100),
          //     //     borderSide: const BorderSide(color: Color.fromARGB(255, 0, 0, 0)),
          //     //   ),
          //     //   errorBorder: OutlineInputBorder(
          //     //     borderSide:
          //     //         const BorderSide(color: Color.fromARGB(255, 239, 14, 2)),
          //     //     borderRadius: BorderRadius.circular(100),
          //     //   ),
          //     //   focusedErrorBorder: OutlineInputBorder(
          //     //     borderSide:
          //     //         const BorderSide(color: Color.fromARGB(255, 239, 14, 2)),
          //     //     borderRadius: BorderRadius.circular(20),
          //     //   ),
          //     //   hintStyle: const TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
          //     //   suffixIconColor: const Color.fromARGB(255, 0, 0, 0),
          //     //   prefixIconColor: const Color.fromARGB(255, 0, 0, 0),
          //     // ),

          //     /////////////////////////////////////////////////////////////////

          //     // textTheme: const TextTheme(
          //     //   bodyLarge: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
          //     //   bodyMedium: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
          //     //   headlineSmall: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
          //     //   titleLarge: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
          //     //   titleMedium: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
          //     //   titleSmall: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
          //     //   bodySmall: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
          //     //   displayMedium: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
          //     //   displayLarge: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),

          //     // ),
          //     // iconTheme: const IconThemeData(
          //     //   color: kAppColor,
          //     // ),
          //     // iconButtonTheme: const IconButtonThemeData(
          //     //     style:
          //     //         ButtonStyle(iconColor: MaterialStatePropertyAll(kAppColor))),
          //     // elevatedButtonTheme: ElevatedButtonThemeData(
          //     //   style: ButtonStyle(
          //     //       backgroundColor: MaterialStateProperty.all(kAppColor)),
          //     // ),
          //     // progressIndicatorTheme: const ProgressIndicatorThemeData(
          //     //   color: Color(0xff0F0961),
          //     // ),
          //     // scaffoldBackgroundColor: const Color(0xfff4f6fa),
          //     // colorScheme: ColorScheme.fromSeed(seedColor: kAppColor)
          //     ),
          // theme: ThemeData().copyWith),
          theme: lightTheme.copyWith(), // الثيم النهاري
          darkTheme: darkTheme, // الثيم الليلي
          themeMode: themeMode, // تحديد الثيم بناءً على الحالة الحالية
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          locale: context.locale,
          routerConfig: router,
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
