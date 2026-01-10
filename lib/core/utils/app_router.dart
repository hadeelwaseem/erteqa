import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sooq_merchant/features/auth/presentation/views/onboarding_view.dart';
import 'package:sooq_merchant/features/dashboard/dashboard_screen.dart';
import '../../features/customization/data/models/store_layout_model.dart';
import '../../features/customization/presentation/cubits/customization_cubit.dart';
import '../../features/customization/presentation/cubits/customization_preview_cubit.dart';

abstract class AppRouter {
  static const kOnBoardingView = '/onBoardingView';
  static const kHomeView = '/homeView';
  static const kDashboardView = '/dashboardView';

  static GoRouter setupRouter(String? token) {
    return GoRouter(
      routes: [
        if (token == null)
          //navigate to Auth/onBoarding Screen (He is not signingIn)
          //The Bellow code is example os how we will continue
          GoRoute(
            path: '/',
            builder: (context, state) => MultiBlocProvider(
              providers: [
                BlocProvider(create: (_) => CustomizationCubit()),
                BlocProvider(
                  create: (context) => CustomizationPreviewCubit(
                    colors: context.read<CustomizationCubit>().state,
                    layout: StoreLayoutModel.defaultLayout(),
                  ),
                ),
              ],
              child: DashboardScreen(),
            ),
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
