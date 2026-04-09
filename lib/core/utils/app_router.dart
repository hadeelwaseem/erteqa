import 'package:go_router/go_router.dart';
import 'package:sooq_merchant/core/utils/service_locator.dart';
import 'package:sooq_merchant/features/homescreen/presentation/views/home_screen.dart';
import 'package:sooq_merchant/features/variantscreen/data/repos/variant_repository.dart';
import 'package:sooq_merchant/features/variantscreen/presentation/views/variant_screen.dart';

abstract class AppRouter {
  static const kOnBoardingView = '/onBoardingView';
  static const kHomeView = '/homeView';
  static const kDashboardView = '/dashboardView';
  static const kMvp2View = '/mvp2';
  
  /// Dynamic screen route: `/variant/:id` where `:id` is the pageId.
  /// 
  /// Routing is explicitly pageId-driven:
  /// - PageId (e.g., 'classic', 'dashboard', 'modern') is extracted from the URL
  /// - Router passes it directly to VariantScreen
  /// - VariantScreen loads the ScreenConfig via VariantRepository
  /// - No additional resolver/factory layers; routing is deterministic
  /// 
  /// Bootstrap strategy (deterministic initial page):
  /// - On app startup, the initial pageId is resolved via ConfigService or a hardcoded default
  /// - App navigates to `/variant/:startupPageId`
  /// - This ensures a predictable entry point
  static const kVariantView = '/variant/:id';

  static GoRouter setupRouter(String? token) {
    return GoRouter(
      routes: [
        if (token == null)
          //navigate to Auth/onBoarding Screen (He is not signingIn)
          // GoRoute(
          //   path: '/',
          //   builder: (context, state) => BlocProvider(
          //     create: (context) => DashboardCubit(getIt<DashboardRepo>()),
          //     child: const DashboardScreen(),
          //   ),
          // ),
          GoRoute(
            path: '/',
            // path: kHomeView,
            builder: (context, state) => const HomeScreen(),
          ),

        // MVP V2: Runtime JSON-driven UI experiment
        GoRoute(
          path: kMvp2View,
          builder: (context, state) => const HomeScreen(),
        ),
        // Dynamic screen route: loads screen config by pageId (deterministically).
        // Route resolution: /variant/:pageId -> VariantScreen(pageId) -> VariantCubit.loadVariant(pageId) -> ScreenConfig
        // Fallback: if pageId not found in path parameters, defaults to 'classic' (bootstrap default).
        GoRoute(
          path: '/variant/:id',
          builder: (context, state) {
            final pageId = state.pathParameters['id'] ?? 'classic';
            return VariantScreen(
              variantId: pageId,
              variantRepository: getIt<VariantRepository>(),
            );
          },
        ),

        //else: the user is SiginedIn and should be navigated to Home screen
        //The Bellow code is example os how we will continue

        // if (token != null)
        //   GoRoute(
        //     path: '/',
        //     builder: (context, state) {
        //       return MultiBlocProvider(
        //         providers: [
        //           // BlocProvider(
        //           //     create: (context) => SubjectsCubit(
        //           //         getIt<HomeRepoImpl>(), gradeId ?? state.extra as String)
        //           //       ..fetchSubjects(
        //           //           gradeId: gradeId ?? state.extra as String)),
        //           BlocProvider(
        //               create: (context) => AdCubit(getIt<HomeRepoImpl>())),
        //           BlocProvider(
        //               create: (context) => SubjectsCubit(
        //                     getIt<HomeRepoImpl>(),
        //                   )),
        //         ],
        //         child: const HomeView(
        //             // gradeId: gradeId ?? state.extra as String,
        //             ),
        //       );
        //     },
        //   ),
      ],
    );
  }
}
